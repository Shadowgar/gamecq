param(
    [string]$ImageTag = "darkspace-legacy-builder:latest"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$revivialRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [System.IO.Path]::GetFullPath((Join-Path -Path $revivialRoot -ChildPath "..\.."))
$dockerfile = Join-Path -Path $revivialRoot -ChildPath "docker\builder\Dockerfile"

Write-Host "Building legacy Linux builder image..."
docker build -t $ImageTag -f $dockerfile $revivialRoot
if ($LASTEXITCODE -ne 0) {
    throw "Failed to build builder image."
}

Write-Host "Running legacy Linux build..."
docker run --rm -v "${workspaceRoot}:/workspace" -e WORKSPACE_ROOT=/workspace $ImageTag
if ($LASTEXITCODE -ne 0) {
    throw "Legacy Linux build failed."
}

Write-Host "Legacy Linux server bootstrap build complete."
