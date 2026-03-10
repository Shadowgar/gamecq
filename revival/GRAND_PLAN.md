# DarkSpace Revival Grand Plan

This document is intentionally duplicated in each repo's `revival/` folder. Keep the copies synchronized.

## Mission

Produce a working, maintainable copy of the game by rewriting the broken foundation in controlled passes instead of repeatedly poking legacy binaries until they crash in different places.

Immediate priority:

- get the headless server stack stable
- modernize the engine/runtime code that is provably unsafe on 64-bit systems
- keep runtime checks short and deliberate
- defer client and renderer overhaul until the server copy is real

## What Changed

The old plan assumed we could keep reviving the original runtime by incremental container and crash debugging. The codebase has now shown that this is not enough.

Observed failure pattern:

- 32-bit type assumptions break on 64-bit Linux
- thread stack defaults are far too small
- time and string code pass invalid pointer types into libc
- DB connectivity mixes legacy client assumptions with modern MariaDB
- repeated runtime attempts are expensive and low-signal until core runtime code is repaired

This means the correct approach is:

- static code sweep first
- compile verification second
- short smoke tests third
- long runtime checks only after a subsystem clears the first three gates

## Working Copy Strategy

### Rule 1: Go Subsystem By Subsystem

Do not attempt a big-bang rewrite of all three repos at once.

Use this order:

1. `medusa` runtime substrate
2. `medusa` network/protocol surface
3. `gamecq` service and DB layer
4. `darkspace` dedicated server path
5. `darkspace` client and renderer path

### Rule 2: Line-By-Line Means Controlled Sweeps

For each subsystem, review and modernize every touched file for:

- type-width correctness
- pointer truncation
- stack safety
- varargs safety
- thread safety
- time and locale safety
- resource ownership
- platform API correctness
- build reproducibility

This is still line-by-line work, but it is done in bounded passes with compile gates instead of across the whole repo in one shot.

### Rule 3: Stop Using Long Runtime Loops As The Primary Tool

Default workflow for each pass:

1. static audit
2. code rewrite
3. compile check
4. targeted fast smoke test

Only after that do we run a containerized service stack.

## Architecture North Star

- `medusa-core`: safe 64-bit-clean runtime, containers, strings, threading, timing, file, serialization, and shared utilities
- `medusa-server`: headless networking, world, and protocol layers with no client-only dependencies
- `gamecq-services`: modernized auth, session, registry, moderation, and process services
- `darkspace-server`: dedicated server runtime and gameplay rules running on the repaired substrate
- `darkspace-client`: later-phase client shell and renderer migration
- `toolchain`: schema validation, asset conversion, and packaging

## Program Phases

### Phase 0: Baseline And Rules

- freeze the current repo state
- document every known crash class and unsafe subsystem
- define hard gates for what counts as "working"

Exit criteria:

- baseline tags exist
- known failure classes are documented
- compile and smoke-test gates are written

### Phase 1: Medusa Runtime Rewrite Pass

Rewrite or heavily modernize the server-critical runtime layer in `medusa`:

- `Types`
- `Thread`
- `Time`
- `String`
- `Log`
- `Event`
- `Process`
- `Reference` and tracking code

Exit criteria:

- server-critical medusa libs build cleanly on 64-bit Windows and Linux
- no known pointer-width or stack-size defects remain in the substrate
- runtime smoke tests no longer die in basic logging, time, or thread startup paths

### Phase 2: Network And Protocol Pass

- modernize socket and network wrappers
- remove resolver and connection assumptions that are unsafe on modern libc
- harden serialization and protocol boundaries

Exit criteria:

- `Network`, `GCQ`, and `World` build on the repaired substrate
- transport startup and DB-adjacent connection paths survive fast smoke tests

### Phase 3: GameCQ Service Pass

- rewrite DB access around a safe adapter
- remove raw SQL formatting from critical paths
- stabilize `MetaServer`, `ProcessServer`, and `MirrorServer`

Exit criteria:

- services start reliably in Docker
- DB connection, registration, and process orchestration work in a short smoke test

### Phase 4: DarkSpace Dedicated Server Pass

- isolate dedicated server code from client-era assumptions
- repair server startup and world load on top of the modernized substrate

Exit criteria:

- `DarkSpaceServer` stays up in the container stack
- server startup, map/content load, and registration are reproducible

### Phase 5: Client And Renderer Pass

- only after the server copy is stable
- define renderer abstraction seam
- migrate away from the D3D9/Win32-era path in controlled slices

Exit criteria:

- client starts on the repaired runtime
- renderer replacement work can proceed without destabilizing the server

## Repo Ownership

- `medusa`: runtime and protocol substrate rewrite
- `gamecq`: service and database rewrite
- `darkspace`: dedicated server stabilization, then client and content modernization

## Non-Goals For The Current Cycle

- full gameplay redesign
- content feature expansion before the server is stable
- long-running binary experiments as the default debugging method
