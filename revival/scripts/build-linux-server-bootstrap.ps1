param(
    [string]$ImageTag = "darkspace-legacy-builder:latest",
    [int]$MakeJobs = 0,
    [switch]$SkipImageBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$revivalRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path -Path $revivalRoot -ChildPath "..\.."))
$dockerfile = Join-Path -Path $revivalRoot -ChildPath "docker\builder\Dockerfile"

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
docker run --rm -v "${workspaceRoot}:/workspace" -e WORKSPACE_ROOT=/workspace -e MAKE_JOBS=$MakeJobs $ImageTag
if ($LASTEXITCODE -ne 0) {
    throw "Legacy Linux build failed."
}

Write-Host "Legacy Linux server bootstrap build complete."
