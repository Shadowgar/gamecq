param(
    [string]$SourcePortsDir = "..\..\darkspace\Ports",
    [string]$RuntimeDataDir = ".\runtime\data"
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
$sourceDir = Resolve-NormalizedPath -PathValue $SourcePortsDir -BasePath $revivalRoot
$targetDir = Resolve-NormalizedPath -PathValue $RuntimeDataDir -BasePath $revivalRoot

if (-not (Test-Path -LiteralPath $sourceDir)) {
    throw "Ports source not found: $sourceDir"
}

if (-not (Test-Path -LiteralPath $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

Copy-Item -Path (Join-Path -Path $sourceDir -ChildPath "*") -Destination $targetDir -Recurse -Force
Write-Host "DarkSpace data staged from $sourceDir to $targetDir"
