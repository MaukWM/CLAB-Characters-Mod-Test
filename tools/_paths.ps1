# Locating the two environments, without depending on what anyone named their folders.
# Dot-sourced by dev-link.ps1 / dev-unlink.ps1.
#
# Order for each: -flag  ->  remembered answer  ->  quick search  ->  whole-drive search  ->  ask.
# Whatever is found gets remembered, so the slow paths run at most once per machine.

$GameName = "Cirno! Lifts a Boulder"
$GameAppId = "4173110"
$PathsFile = Join-Path $PSScriptRoot "dev-paths.local.json"

function Get-SavedPaths {
    if (-not (Test-Path $PathsFile)) { return @{} }
    try { $o = Get-Content $PathsFile -Raw | ConvertFrom-Json } catch { return @{} }
    $h = @{}
    foreach ($p in $o.PSObject.Properties) { $h[$p.Name] = $p.Value }
    return $h
}

function Save-SavedPath($key, $value) {
    $h = Get-SavedPaths
    $h[$key] = $value
    $h | ConvertTo-Json | Set-Content $PathsFile -Encoding utf8
}

function Test-Decomp($path) {
    if (-not $path) { return $false }
    $proj = Join-Path $path "project.godot"
    if (-not (Test-Path $proj)) { return $false }
    return (Get-Content $proj -Raw -ErrorAction SilentlyContinue) -match [regex]::Escape("config/name=`"$GameName`"")
}

function Test-SteamGame($path) {
    if (-not $path) { return $false }
    return Test-Path (Join-Path $path "$GameName.exe")
}

function Select-One($hits, $where) {
    $dirs = @($hits | ForEach-Object { $_.DirectoryName } | Select-Object -Unique)
    if ($dirs.Count -eq 1) { return $dirs[0] }
    if ($dirs.Count -gt 1) {
        throw ("Several copies of the decompiled project $where - pass -Decomp with the one you want:`n" +
               (($dirs | ForEach-Object { "  $_" }) -join "`n"))
    }
    return $null
}

# Quick pass: a handful of likely roots, shallow. ~20 ms when it hits.
function Find-DecompQuick($repo) {
    $roots = @(
        (Split-Path -Parent $repo)
        (Split-Path -Parent (Split-Path -Parent $repo))
        "$env:USERPROFILE\Desktop"
        "$env:USERPROFILE\Documents"
        "$env:USERPROFILE\Downloads"
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

    foreach ($r in $roots) {
        Write-Host "    looking in $r"
        $script:Checked += $r
        $hits = @(Get-ChildItem -LiteralPath $r -Filter project.godot -Recurse -Depth 3 -File -ErrorAction SilentlyContinue |
                  Where-Object { Test-Decomp $_.DirectoryName })
        $one = Select-One $hits "under $r"
        if ($one) { return $one }
    }
    return $null
}

# Slow pass: every fixed drive, skipping system and package folders. ~1 s here.
function Find-DecompDeep {
    $skip = @('Windows','Program Files','Program Files (x86)','ProgramData','$Recycle.Bin',
              'System Volume Information','AppData','node_modules','.git','OneDriveTemp')
    $hits = @()
    foreach ($d in (Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3").DeviceID) {
        Write-Host "    scanning drive $d (this can take a few seconds)"
        $script:Checked += "$d\ (whole drive)"
        $tops = Get-ChildItem "$d\" -Directory -Force -ErrorAction SilentlyContinue |
                Where-Object { $skip -notcontains $_.Name }
        foreach ($t in $tops) {
            $hits += Get-ChildItem -LiteralPath $t.FullName -Filter project.godot -Recurse -Depth 6 -File -ErrorAction SilentlyContinue |
                     Where-Object { Test-Decomp $_.DirectoryName }
        }
    }
    return Select-One $hits "on this machine"
}

# Steam knows where it installed things - ask it rather than guessing a path.
function Find-SteamGame {
    $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { return $null }
    $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
    if (-not (Test-Path $vdf)) { return $null }
    $libs = @($steam) + @(Select-String -Path $vdf -Pattern '"path"\s+"(.+?)"' |
                          ForEach-Object { $_.Matches[0].Groups[1].Value -replace '\\', '\' })
    foreach ($l in ($libs | Select-Object -Unique)) {
        $manifest = Join-Path $l "steamapps\appmanifest_$GameAppId.acf"
        if (-not (Test-Path $manifest)) { continue }
        $m = Select-String -Path $manifest -Pattern '"installdir"\s+"(.+?)"'
        if (-not $m) { continue }
        $dir = Join-Path $l ("steamapps\common\" + $m.Matches[0].Groups[1].Value)
        if (Test-SteamGame $dir) { return $dir }
    }
    return $null
}

function Resolve-Path2($kind, $explicit, $repo) {
    $script:Checked = @()
    $validate = if ($kind -eq "decomp") { ${function:Test-Decomp} } else { ${function:Test-SteamGame} }
    $label = if ($kind -eq "decomp") { "decompiled Godot project" } else { "Steam install of the game" }
    $flag = if ($kind -eq "decomp") { "-Decomp" } else { "-SteamDir" }

    if ($explicit) {
        if (-not (& $validate $explicit)) { throw "$explicit is not the $label." }
        Save-SavedPath $kind $explicit; return $explicit
    }
    $saved = (Get-SavedPaths)[$kind]
    if ($saved -and (& $validate $saved)) { return $saved }

    if ($kind -eq "decomp") {
        $found = Find-DecompQuick $repo
        if (-not $found) { Write-Host "  searching for the $label ..."; $found = Find-DecompDeep }
    } else {
        $found = Find-SteamGame
    }
    if ($found) { Write-Host "  found $($kind): $found"; Save-SavedPath $kind $found; return $found }

    throw ("Could not find the $label anywhere. Looked in:`n" +
           (($script:Checked | ForEach-Object { "  $_" }) -join "`n") +
           "`n`nPoint at it directly:`n  .\tools\dev-link.ps1 $flag `"<path>`"`n" +
           "It is remembered after that, so you only pass it once.")
}
