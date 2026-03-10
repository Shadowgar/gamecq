param(
    [string]$RuntimeRoot = ".\runtime"
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
$runtimeRoot = Resolve-NormalizedPath -PathValue $RuntimeRoot -BasePath $revivalRoot
$binDir = Join-Path -Path $runtimeRoot -ChildPath "bin"
$configDir = Join-Path -Path $runtimeRoot -ChildPath "config"

$requiredDirs = @(
    $runtimeRoot,
    $binDir,
    $configDir,
    (Join-Path -Path $runtimeRoot -ChildPath "logs"),
    (Join-Path -Path $runtimeRoot -ChildPath "mirror"),
    (Join-Path -Path $runtimeRoot -ChildPath "data"),
    (Join-Path -Path $runtimeRoot -ChildPath "webroot")
)

$missing = New-Object System.Collections.Generic.List[string]

foreach ($dir in $requiredDirs) {
    if (-not (Test-Path -LiteralPath $dir)) {
        $missing.Add("Missing directory: $dir")
    }
}

$requiredBinFiles = @(
    "MetaServer",
    "ProcessServer",
    "MirrorServer",
    "DarkSpaceServer",
    "libGCQDB.so",
    "libGCQS.so",
    "libDarkSpace.so",
    "libMedusa.so",
    "libNetwork.so",
    "libGCQ.so",
    "libRender3D.so",
    "libWorld.so"
)

foreach ($file in $requiredBinFiles) {
    $path = Join-Path -Path $binDir -ChildPath $file
    if (-not (Test-Path -LiteralPath $path)) {
        $missing.Add("Missing runtime binary: $path")
    }
}

$mysqlLibPattern = Get-ChildItem -Path $binDir -Filter "libmysqlclient.so*" -File -ErrorAction SilentlyContinue
if ($mysqlLibPattern.Count -eq 0) {
    $missing.Add("Missing runtime binary: $binDir\\libmysqlclient.so*")
}

$luaLibPattern = Get-ChildItem -Path $binDir -Filter "liblua5.1.so*" -File -ErrorAction SilentlyContinue
if ($luaLibPattern.Count -eq 0) {
    $missing.Add("Missing runtime binary: $binDir\\liblua5.1.so*")
}

$requiredConfigFiles = @(
    "MetaServer.ini",
    "ProcessServer.ini",
    "MirrorServer.ini",
    "config.ini"
)

foreach ($file in $requiredConfigFiles) {
    $path = Join-Path -Path $configDir -ChildPath $file
    if (-not (Test-Path -LiteralPath $path)) {
        $missing.Add("Missing runtime config: $path")
    }
}

if ($missing.Count -gt 0) {
    Write-Host "Runtime preflight failed:"
    foreach ($item in $missing) {
        Write-Host " - $item"
    }
    exit 1
}

Write-Host "Runtime preflight passed."
Write-Host "Runtime root: $runtimeRoot"
