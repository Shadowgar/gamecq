param(
    [string]$RuntimeConfigDir = ".\runtime\config"
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

function Set-IniValue {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )
    $pattern = "(?m)^\s*" + [Regex]::Escape($Key) + "\s*=.*$"
    $replacement = "$Key=$Value"
    if ($Text -match $pattern) {
        return [Regex]::Replace($Text, $pattern, $replacement)
    }

    return ($Text.TrimEnd() + [Environment]::NewLine + $replacement + [Environment]::NewLine)
}

$revivialRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Resolve-NormalizedPath -PathValue ".." -BasePath $revivialRoot
$darkspaceRoot = Resolve-NormalizedPath -PathValue "..\..\darkspace" -BasePath $revivialRoot
$targetDir = Resolve-NormalizedPath -PathValue $RuntimeConfigDir -BasePath $revivialRoot

if (-not (Test-Path -LiteralPath $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$processSource = Join-Path -Path $repoRoot -ChildPath "ProcessServer\ProcessServer.ini"
$mirrorSource = Join-Path -Path $repoRoot -ChildPath "MirrorServer\MirrorServer.ini"
$darkspaceSource = Join-Path -Path $darkspaceRoot -ChildPath "DarkSpaceServer\config.ini"

foreach ($sourcePath in @($processSource, $mirrorSource, $darkspaceSource)) {
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Required source config missing: $sourcePath"
    }
}

$metaTemplate = @"
[MetaServer]
dbname=darkspace
dbaddress=db
dbport=3306
dbuid=darkspace
dbpw=darkspace_local_only
maxConnections=8
motdFile=
address=0.0.0.0
port=9000
maxClients=1000
gameId=2
eventNotifyTime=3600
logFile=../logs/MetaServer.log
logLevel=3
shutdownTime=30
"@
Set-Content -Path (Join-Path -Path $targetDir -ChildPath "MetaServer.ini") -Value $metaTemplate -NoNewline
Write-Host "Staged MetaServer.ini"

$processConfig = Get-Content -Path $processSource -Raw
$processConfig = Set-IniValue -Text $processConfig -Key "metaAddress" -Value "metaserver"
$processConfig = Set-IniValue -Text $processConfig -Key "metaPort" -Value "9000"
$processConfig = Set-IniValue -Text $processConfig -Key "mirrorAddress" -Value "mirrorserver"
$processConfig = Set-IniValue -Text $processConfig -Key "mirrorPort" -Value "9100"
$processConfig = Set-IniValue -Text $processConfig -Key "address" -Value "0.0.0.0"
$processConfig = Set-IniValue -Text $processConfig -Key "logFile" -Value "../logs/ProcessServer.log"
$processConfig = Set-IniValue -Text $processConfig -Key "doUpdate" -Value "0"
Set-Content -Path (Join-Path -Path $targetDir -ChildPath "ProcessServer.ini") -Value $processConfig -NoNewline
Write-Host "Staged ProcessServer.ini"

$mirrorConfig = Get-Content -Path $mirrorSource -Raw
$mirrorConfig = Set-IniValue -Text $mirrorConfig -Key "metaAddress" -Value "metaserver"
$mirrorConfig = Set-IniValue -Text $mirrorConfig -Key "metaPort" -Value "9000"
$mirrorConfig = Set-IniValue -Text $mirrorConfig -Key "catalog" -Value "../mirror/alpha.crc"
$mirrorConfig = Set-IniValue -Text $mirrorConfig -Key "mirror" -Value "../mirror/"
$mirrorConfig = Set-IniValue -Text $mirrorConfig -Key "logFile" -Value "../logs/MirrorServer.log"
$mirrorConfig = Set-IniValue -Text $mirrorConfig -Key "address" -Value "0.0.0.0"
$mirrorConfig = Set-IniValue -Text $mirrorConfig -Key "port" -Value "9100"
$mirrorConfig = Set-IniValue -Text $mirrorConfig -Key "LinkCount" -Value "0"
Set-Content -Path (Join-Path -Path $targetDir -ChildPath "MirrorServer.ini") -Value $mirrorConfig -NoNewline
Write-Host "Staged MirrorServer.ini"

$darkspaceConfig = Get-Content -Path $darkspaceSource -Raw
$darkspaceConfig = Set-IniValue -Text $darkspaceConfig -Key "metaAddress" -Value "metaserver"
$darkspaceConfig = Set-IniValue -Text $darkspaceConfig -Key "metaPort" -Value "9000"
$darkspaceConfig = Set-IniValue -Text $darkspaceConfig -Key "address" -Value "0.0.0.0"
$darkspaceConfig = Set-IniValue -Text $darkspaceConfig -Key "port" -Value "9020"
$darkspaceConfig = Set-IniValue -Text $darkspaceConfig -Key "data" -Value "../data/"
$darkspaceConfig = Set-IniValue -Text $darkspaceConfig -Key "storage" -Value "../data/Storage/"
$darkspaceConfig = Set-IniValue -Text $darkspaceConfig -Key "saveFile" -Value "../data/Debug.wob"
$darkspaceConfig = Set-IniValue -Text $darkspaceConfig -Key "logFile" -Value "../logs/DarkSpaceServer.log"
Set-Content -Path (Join-Path -Path $targetDir -ChildPath "config.ini") -Value $darkspaceConfig -NoNewline
Write-Host "Staged config.ini"

Write-Host "Server config staging complete."
