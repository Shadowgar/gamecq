# GameCQ Revival (Server Orchestration)

This folder tracks all server orchestration work in `gamecq`.

## Scope in this repo

- Primary backend services:
  - `MetaServer`
  - `ProcessServer`
  - `MirrorServer`
  - supporting admin/service tooling
- Server-side config normalization for local/container use
- Docker orchestration artifacts for backend bring-up

## Canonical files in this folder

- `docker-compose.server.yml`: backend stack definition
- `.env.example`: required runtime variables
- `docker/runner/`: generic Linux runner image and entrypoint
- `docker/builder/`: legacy Linux build container for server bootstrap artifacts
- `scripts/build-linux-server-bootstrap.ps1`: builds Linux server artifacts from legacy makefiles via Docker
- `scripts/stage-medusa-runtime.ps1`: stages shared Medusa runtime artifacts into `runtime/bin`
- `scripts/stage-server-binaries.ps1`: stages built server executables into `runtime/bin`
- `scripts/stage-server-config.ps1`: stages container-ready server config files into `runtime/config`
- `scripts/stage-darkspace-data.ps1`: stages `darkspace/Ports` content into `runtime/data`
- `scripts/validate-runtime.ps1`: validates required runtime layout before compose startup
- `COMPONENT_MAP.md`: service ownership and dependencies
- `DRIFT_LOG.md`: append-only change history
- `MODERNIZATION_PLAN.md`: backend modernization phases

## Drift control rules

- Any change to service ports, credentials, hostnames, startup command, or DB schema assumptions must be logged in `DRIFT_LOG.md`.
- Any change that impacts `darkspace` runtime or `medusa` shared protocol must be cross-logged in those repos' `revivial/DRIFT_LOG.md`.
