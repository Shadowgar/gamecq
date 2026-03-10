# GameCQ Revival Plan

This plan assumes `medusa` is being repaired first and that `gamecq` work should stop wasting time on long crash loops caused by substrate failures.

## Repo Role

`gamecq` is the service layer:

- DB adapter and query layer
- auth and sessions
- server registry and orchestration
- moderation, chat, mirror, and process services

## Current Assessment

- service logic is mixed with legacy DB and runtime assumptions
- SQL is built by formatting strings in hot paths
- DB connectivity still reflects old MySQL client expectations
- service startup is currently blocked by both `medusa` runtime defects and `gamecq`-local DB/query issues

## New Execution Order

### Pass 1: DB Boundary Rewrite

Review and modernize line by line:

- `GCQDB/*`
- DB connection lifecycle
- DB query helpers
- insert-id and result handling

Goals:

- clean MariaDB compatibility
- no unsafe client-ABI assumptions
- no resolver surprises hidden in the DB layer

### Pass 2: MetaServer Runtime Pass

Once the shared runtime is repaired:

- review `MetaServer` startup path line by line
- replace formatted SQL hot paths in the startup and registration flow
- isolate service registration, connection pooling, and logging behavior

This is the first service that must become stable.

### Pass 3: ProcessServer and MirrorServer Pass

- port fixes from `MetaServer`
- remove duplicate unsafe patterns
- establish short startup smoke tests

### Pass 4: Security and Schema Modernization

Only after the services are starting reliably:

- replace high-risk auth and session paths
- move schema toward transactional and modern defaults
- add health and operational visibility

## Working Rules For This Repo

- do not use long service-restart loops as the default debugging method
- when a file is touched, review it for 64-bit safety, DB safety, and ownership safety
- prioritize short deterministic checks: compile, targeted service start, direct query path validation
- keep compatibility behavior only where it buys forward progress

## Immediate Backlog

- finish the DB adapter cleanup in `GCQDB`
- document every startup-path SQL formatting hot spot in `MetaServer`
- define a minimal service smoke test that completes in under a minute
- defer larger auth redesign until startup and registration are stable

## Success Signal

`gamecq` is successful for the current phase when `MetaServer`, `ProcessServer`, and `MirrorServer` can start on the repaired shared runtime and their DB boundary is no longer the source of legacy client-ABI crashes.
