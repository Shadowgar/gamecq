# Component Map (gamecq)

## Core server services

- `MetaServer/`
  - Account/session/profile authority.
  - Reads/writes MySQL tables in `gamecq.sql` schema.
- `ProcessServer/`
  - Process orchestration for managed service instances.
  - Talks to Mirror and Meta services.
- `MirrorServer/`
  - Content distribution/mirror service.
- `Gcqs/`
  - Shared server-side logic and protocol handling.

## Related server tooling

- `ProcessClientCLI/`
  - CLI control path for ProcessServer.
- `Service/`
  - Legacy service wrapper/supervision path.
- `ChronDemon/`, `RotateLogs/`, `LogServer/`
  - Operational background utilities.

## Web-related artifacts

- `Web.sln`
  - Legacy web solution reference points to external HTTP path (not locally buildable as-is).
- `revivial/runtime/webroot` (new runtime contract)
  - Container-served web root path for server-side web hosting in compose.

## External dependencies

- MySQL-compatible database (historically MySQL schema from `gamecq.sql`)
- `medusa` shared runtime/libs for networking and protocol layer
- `darkspace` server process for full game runtime flow
