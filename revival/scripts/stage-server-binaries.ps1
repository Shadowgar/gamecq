param(
    [string]$GamecqBuildDir = "out\server-bootstrap\Release",
    [string]$DarkspaceBuildDir = "..\..\darkspace\out\server-bootstrap\Release",
    [string]$MedusaBuildDir = "..\..\medusa\out\server-bootstrap\Release",
    [string]$RuntimeBinDir = ".\runtime\bin"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-NormalizedPath {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [Parameter(Mandatory = $true)][string]$BasePath
    )
    return [System.IO.Path]::GetFullPath((Join-Path -Path $BasePath -ChildPath $PathValue))
}

$revivalRoot = Split-Path -Parent $PSScriptRoot
$gamecqRoot = Resolve-NormalizedPath -PathValue ".." -BasePath $revivalRoot
$sourceGamecq = Resolve-NormalizedPath -PathValue $GamecqBuildDir -BasePath $gamecqRoot
$sourceDarkspace = Resolve-NormalizedPath -PathValue $DarkspaceBuildDir -BasePath $revivalRoot
$sourceMedusa = Resolve-NormalizedPath -PathValue $MedusaBuildDir -BasePath $revivalRoot
$targetDir = Resolve-NormalizedPath -PathValue $RuntimeBinDir -BasePath $revivalRoot

if (-not (Test-Path -LiteralPath $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$map = @(
    @{ Name = "MetaServer"; SourceBase = $sourceGamecq },
    @{ Name = "ProcessServer"; SourceBase = $sourceGamecq },
    @{ Name = "MirrorServer"; SourceBase = $sourceGamecq },
    @{ Name = "DarkSpaceServer"; SourceBase = $sourceDarkspace }
)

foreach ($entry in $map) {
    $sourcePath = Join-Path -Path $entry.SourceBase -ChildPath $entry.Name
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing binary for staging: $sourcePath"
    }

    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path -Path $targetDir -ChildPath $entry.Name) -Force
    Write-Host "Staged $($entry.Name)"
}

$sharedLibMap = @(
    @{ Name = "libGCQDB.so"; SourceBase = $sourceGamecq },
    @{ Name = "libGCQS.so"; SourceBase = $sourceGamecq },
    @{ Name = "libDarkSpace.so"; SourceBase = $sourceDarkspace },
    @{ Name = "libMedusa.so"; SourceBase = $sourceMedusa },
    @{ Name = "libNetwork.so"; SourceBase = $sourceMedusa },
    @{ Name = "libGCQ.so"; SourceBase = $sourceMedusa },
    @{ Name = "libRender3D.so"; SourceBase = $sourceMedusa },
    @{ Name = "libWorld.so"; SourceBase = $sourceMedusa }
)

foreach ($entry in $sharedLibMap) {
    $sourcePath = Join-Path -Path $entry.SourceBase -ChildPath $entry.Name
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing shared library for staging: $sourcePath"
    }

    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path -Path $targetDir -ChildPath $entry.Name) -Force
    Write-Host "Staged $($entry.Name)"
}

# Use distro mysql client runtime from runner image to avoid legacy libmysqlclient crashes.
Get-ChildItem -Path $targetDir -Filter "libmysqlclient.so*" -File -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Force
    Write-Host "Removed stale $($_.Name)"
}

$luaLibs = Get-ChildItem -Path $sourceDarkspace -Filter "liblua5.1.so*" -File -ErrorAction SilentlyContinue
if ($luaLibs.Count -eq 0) {
    throw "Missing lua runtime libs for staging in: $sourceDarkspace"
}
foreach ($lib in $luaLibs) {
    Copy-Item -LiteralPath $lib.FullName -Destination (Join-Path -Path $targetDir -ChildPath $lib.Name) -Force
    Write-Host "Staged $($lib.Name)"
}

Write-Host "Server binary staging complete."
