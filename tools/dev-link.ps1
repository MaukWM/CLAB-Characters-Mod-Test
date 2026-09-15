# Links this repo's charmodtest/ into the decomp project (for F5 in the editor) and into the Steam
# install (for playing the real build), via directory junctions - no copies, no admin rights.
#
#   .\tools\dev-link.ps1
#   .\tools\dev-link.ps1 -SkipSteam        # only the decomp
#   .\tools\dev-link.ps1 -SkipDecomp       # only Steam
#   .\tools\dev-link.ps1 -Decomp "D:\my\decomp" -SteamDir "D:\my\steam\CLAB"
param(
    [string]$Decomp = "",
    [string]$SteamDir = "",
    [switch]$SkipDecomp,
    [switch]$SkipSteam
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repo "charmodtest"

. (Join-Path $PSScriptRoot "_paths.ps1")

if (-not $SkipDecomp) { $Decomp = Resolve-Path2 "decomp" $Decomp $repo }
if (-not $SkipSteam)  { $SteamDir = Resolve-Path2 "steam"  $SteamDir $repo }

$autoloadLine = 'CharModTest="*res://charmodtest/mod_entry.gd"'

if (-not (Test-Path $src)) { throw "No charmodtest folder at $src - is this script still inside the repo's tools\ folder?" }

# Test-Path follows the link, so a junction whose target is gone reports $false while the
# directory entry still exists and blocks mklink. Look at the parent listing instead.
function Get-Entry($target) {
    $parent = Split-Path -Parent $target
    $leaf = Split-Path -Leaf $target
    if (-not (Test-Path $parent)) { return $null }
    return Get-ChildItem -LiteralPath $parent -Force | Where-Object { $_.Name -eq $leaf } | Select-Object -First 1
}

function Link-Folder($target) {
    $entry = Get-Entry $target
    if ($entry -ne $null) {
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $current = $entry.Target
            if ($current -eq $src) { Write-Host "  already linked: $target"; return }
            Write-Host "  replacing stale link: $target -> $current"
            cmd /c rmdir "`"$target`"" | Out-Null
        } else {
            throw "A real folder already exists at $target - move it away first."
        }
    }
    cmd /c mklink /J "`"$target`"" "`"$src`"" | Out-Null
    $entry = Get-Entry $target
    if ($entry -eq $null -or -not ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "mklink reported success but $target is not a junction."
    }
    Write-Host "  linked: $target -> $src"
}

if (-not $SkipDecomp) {
    Write-Host "Decomp project: $Decomp"
    $proj = Join-Path $Decomp "project.godot"
    if (-not (Test-Path $proj)) { throw "No project.godot in $Decomp - pass -Decomp with the right path." }
    Link-Folder (Join-Path $Decomp "charmodtest")

    # Dev-only autoload so F5 runs the mod the way override.cfg would in the shipped game.
    # Inserted at the top of [autoload] so it loads before the game's own autoloads, which is
    # what autoload_prepend does in the shipped build.
    $text = Get-Content $proj -Raw
    if ($text.Contains($autoloadLine)) {
        Write-Host "  autoload already in project.godot"
    } else {
        if ($text -match '(?m)^\[autoload\]\r?$') {
            $text = $text -replace '(?m)(^\[autoload\]\r?\n)', "`$1$autoloadLine`n"
        } else {
            $text = $text.TrimEnd() + "`n`n[autoload]`n$autoloadLine`n"
        }
        # Never claim success without checking - a silent no-op here means F5 runs without the mod.
        if (-not $text.Contains($autoloadLine)) {
            throw "Could not add the autoload to $proj. Add this under [autoload] by hand:`n  $autoloadLine"
        }
        $backup = "$proj.pre-charmodtest"
        if (-not (Test-Path $backup)) { Copy-Item $proj $backup; Write-Host "  backed up project.godot -> $(Split-Path -Leaf $backup)" }
        Set-Content -Path $proj -Value $text -Encoding utf8 -NoNewline
        Write-Host "  added autoload to project.godot"
    }
}

if (-not $SkipSteam) {
    Write-Host "Steam install: $SteamDir"
    if (-not (Test-Path (Join-Path $SteamDir "Cirno! Lifts a Boulder.exe"))) { throw "Game exe not found in $SteamDir - pass -SteamDir with the right path." }
    Link-Folder (Join-Path $SteamDir "charmodtest")
    Copy-Item (Join-Path $repo "charmodtest\override.cfg") (Join-Path $SteamDir "override.cfg") -Force
    Write-Host "  override.cfg copied (lists both Lifters and CharModTest; a missing one is harmless)"
}

Write-Host "Done. Undo with tools\dev-unlink.ps1"
