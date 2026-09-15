# Removes the junctions created by dev-link.ps1. Only the links are removed, never the repo.
param(
    [string]$Decomp = "",
    [string]$SteamDir = ""
)

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot

. (Join-Path $PSScriptRoot "_paths.ps1")

if (-not $SkipDecomp) { $Decomp = Resolve-Path2 "decomp" $Decomp $repo }
if (-not $SkipSteam)  { $SteamDir = Resolve-Path2 "steam"  $SteamDir $repo }


function Unlink-Folder($target) {
    if (-not (Test-Path $target)) { Write-Host "  not present: $target"; return }
    $item = Get-Item $target -Force
    if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        Write-Host "  SKIPPED (real folder, not a junction): $target"
        return
    }
    # rmdir on a junction deletes the link only. Never use Remove-Item -Recurse here.
    cmd /c rmdir "`"$target`"" | Out-Null
    Write-Host "  unlinked: $target"
}

Unlink-Folder (Join-Path $Decomp "charmodtest")
Unlink-Folder (Join-Path $SteamDir "charmodtest")

$proj = Join-Path $Decomp "project.godot"
if (Test-Path $proj) {
    $text = Get-Content $proj -Raw
    $new = $text -replace 'CharModTest="\*res://charmodtest/mod_entry.gd"\r?\n', ''
    if ($new -ne $text) { Set-Content -Path $proj -Value $new -Encoding utf8 -NoNewline; Write-Host "  removed CharModTest autoload from project.godot" }
}

$cfg = Join-Path $SteamDir "override.cfg"
if (Test-Path $cfg) {
    Write-Host "  NOTE: $cfg left in place (Lifters may rely on it). Delete it by hand if you have no other mods."
}
