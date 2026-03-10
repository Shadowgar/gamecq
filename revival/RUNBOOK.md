# Server Container Runbook

## Purpose

Define repeatable startup path for server-side stack and reduce config drift.

## Layout expected by compose

Create these directories under `gamecq/revival/runtime/`:

- `bin/` (service binaries)
- `config/` (service config files)
- `logs/`
- `mirror/`
- `data/`
- `webroot/`

## Required binaries (expected names)

- `MetaServer`
- `ProcessServer`
- `MirrorServer`
- `DarkSpaceServer`

## Required config files (expected names)

- `MetaServer.ini`
- `ProcessServer.ini`
- `MirrorServer.ini`
- `config.ini` (for DarkSpaceServer)

## Bring-up commands

```bash
cp .env.example .env
docker compose -f docker-compose.server.yml up -d --build
docker compose -f docker-compose.server.yml logs -f
```

## Stage medusa runtime dependencies

Before starting server containers, stage shared `medusa` runtime DLLs into `runtime/bin` (Windows host/runtime compatibility helper):

```powershell
Set-Location d:\DarkSpace\gamecq\revival
powershell -ExecutionPolicy Bypass -File .\scripts\stage-medusa-runtime.ps1
```

By default this script copies from:

- `d:\DarkSpace\medusa\out\cmake-bootstrap\Release\Medusa.dll`
- `d:\DarkSpace\medusa\out\cmake-bootstrap\Release\Network.dll`

Optional symbols (`*.pdb`) are copied when present.

## Build Linux server bootstrap artifacts (container runner targets)

Produce Linux binaries/shared libs using legacy makefiles in a build container:

```powershell
Set-Location d:\DarkSpace\gamecq\revival
powershell -ExecutionPolicy Bypass -File .\scripts\build-linux-server-bootstrap.ps1
```

This emits release artifacts to:

- `medusa/out/server-bootstrap/Release`
- `gamecq/out/server-bootstrap/Release`
- `darkspace/out/server-bootstrap/Release`

## Stage server binaries

After building server executables, stage them into `runtime/bin`:

```powershell
Set-Location d:\DarkSpace\gamecq\revival
powershell -ExecutionPolicy Bypass -File .\scripts\stage-server-binaries.ps1
```

Default source expectations:

- `gamecq/out/server-bootstrap/Release/MetaServer`
- `gamecq/out/server-bootstrap/Release/ProcessServer`
- `gamecq/out/server-bootstrap/Release/MirrorServer`
- `darkspace/out/server-bootstrap/Release/DarkSpaceServer`
- plus required shared libs (`lib*.so`) from the same output roots

## Stage server configs for container networking

Generate container-ready configs in `runtime/config`:

```powershell
Set-Location d:\DarkSpace\gamecq\revival
powershell -ExecutionPolicy Bypass -File .\scripts\stage-server-config.ps1
```

This produces:

- `MetaServer.ini` (generated baseline; includes DB host `db`)
- `ProcessServer.ini` (rewritten to use `metaserver` and `mirrorserver`)
- `MirrorServer.ini` (rewritten to use `metaserver` and `../mirror/`)
- `config.ini` (DarkSpaceServer config rewritten for container paths and `metaserver`)

## Stage DarkSpace server data

Copy DarkSpace port data required by `DarkSpaceServer` context loading:

```powershell
Set-Location d:\DarkSpace\gamecq\revival
powershell -ExecutionPolicy Bypass -File .\scripts\stage-darkspace-data.ps1
```

This stages `darkspace/Ports/*` into `runtime/data`.

## Validate runtime layout before compose

Run preflight validation:

```powershell
Set-Location d:\DarkSpace\gamecq\revival
powershell -ExecutionPolicy Bypass -File .\scripts\validate-runtime.ps1
```

This checks required `runtime/` folders, required configs, Medusa runtime DLLs, and expected service binaries.

## Current known gap

Compose/runtime contract is in place, but this repo does not yet produce Linux server binaries directly in-container. Next step is a build pipeline that emits binaries into `revival/runtime/bin`.

Database service is currently started with `--sql_mode=` to accept legacy `gamecq.sql` defaults.

Server services now reference configs from `runtime/config` (`../config/*.ini`) and the runner entrypoint fails fast if the service binary or config file is missing.

Current runtime blockers after bootstrap build:

- `metaserver` container restarts with exit code `139` (segfault) in full-stack compose run.
- `processserver` container restarts with exit code `139` (segfault) in full-stack compose run.
- `mirrorserver` container restarts with exit code `139` (segfault) in full-stack compose run.
- `darkspaceserver` container restarts with exit code `1` in full-stack compose run.
- `db` and `web` are currently the only stable services in the stack smoke test.

## Web service note

`web` currently serves static files from `runtime/webroot` via `nginx`.
The legacy `Web.sln` in this repository points to an external VB project URL and is not directly container-buildable in current form.
