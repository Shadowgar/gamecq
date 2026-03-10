param(
    [string]$MedusaBuildDir = "..\..\medusa\out\cmake-bootstrap\Release",
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

$scriptBase = Split-Path -Parent $PSScriptRoot
$sourceDir = Resolve-NormalizedPath -PathValue $MedusaBuildDir -BasePath $scriptBase
$targetDir = Resolve-NormalizedPath -PathValue $RuntimeBinDir -BasePath $scriptBase

if (-not (Test-Path -LiteralPath $sourceDir)) {
    throw "Medusa build directory not found: $sourceDir"
}

if (-not (Test-Path -LiteralPath $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$requiredFiles = @(
    "Medusa.dll",
    "Network.dll"
)

foreach ($file in $requiredFiles) {
    $sourceFile = Join-Path -Path $sourceDir -ChildPath $file
    if (-not (Test-Path -LiteralPath $sourceFile)) {
        throw "Required artifact missing: $sourceFile"
    }

    Copy-Item -LiteralPath $sourceFile -Destination (Join-Path -Path $targetDir -ChildPath $file) -Force
    Write-Host "Staged $file"
}

$optionalFiles = @(
    "Medusa.pdb",
    "Network.pdb"
)

foreach ($file in $optionalFiles) {
    $sourceFile = Join-Path -Path $sourceDir -ChildPath $file
    if (Test-Path -LiteralPath $sourceFile) {
        Copy-Item -LiteralPath $sourceFile -Destination (Join-Path -Path $targetDir -ChildPath $file) -Force
        Write-Host "Staged optional $file"
    }
}

Write-Host "Medusa runtime staging complete."
