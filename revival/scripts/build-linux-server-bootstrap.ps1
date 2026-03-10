param(
    [string]$ImageTag = "darkspace-legacy-builder:latest",
    [int]$MakeJobs = 0,
    [ValidateSet("full", "core", "server", "meta")]
    [string]$BuildScope = "full",
    [string]$CcacheDir = ".\out\ccache",
    [switch]$SkipImageBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$revivalRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path -Path $revivalRoot -ChildPath "..\.."))
$dockerfile = Join-Path -Path $revivalRoot -ChildPath "docker\builder\Dockerfile"
$ccacheRoot = [System.IO.Path]::GetFullPath((Join-Path -Path $revivalRoot -ChildPath $CcacheDir))

if (-not (Test-Path -LiteralPath $ccacheRoot)) {
    New-Item -ItemType Directory -Path $ccacheRoot -Force | Out-Null
}

Write-Host "Building legacy Linux builder image..."
if (-not $SkipImageBuild) {
    docker build -t $ImageTag -f $dockerfile $revivalRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to build builder image."
    }
} else {
    Write-Host "Skipping builder image build."
}

if ($MakeJobs -le 0) {
    $MakeJobs = [Environment]::ProcessorCount
}

Write-Host "Running legacy Linux build..."
docker run --rm -v "${workspaceRoot}:/workspace" -v "${ccacheRoot}:/ccache" -e WORKSPACE_ROOT=/workspace -e MAKE_JOBS=$MakeJobs -e BUILD_SCOPE=$BuildScope -e CCACHE_DIR=/ccache $ImageTag
if ($LASTEXITCODE -ne 0) {
    throw "Legacy Linux build failed."
}

Write-Host "Legacy Linux server bootstrap build complete."
