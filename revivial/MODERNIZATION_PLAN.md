# GameCQ Modernization Plan

This plan aligns backend services with the `medusa` modernization effort.

## Objectives

- Keep backend services runnable during migration.
- Reduce security and maintenance debt in auth, DB access, and service orchestration.
- Move from legacy build assumptions to repeatable modern build/release flow.

## Phase 1: Stabilize and Isolate

- Keep `MetaServer`, `ProcessServer`, `MirrorServer` running in the container stack.
- Isolate legacy code paths behind explicit compatibility guards.
- Keep startup contracts stable for dependent services.

## Phase 2: Security and Data Layer Upgrade

- Replace legacy password flow with modern password hashing and token/session model.
- Remove replay-style auth paths permanently.
- Introduce parameterized DB access in high-risk query paths first.
- Add migration scripts for DB schema evolution.

## Phase 3: Build/Release Modernization

- Add modern build definitions that emit Linux server binaries for containers.
- Add CI build + smoke tests for service startup and health endpoints.
- Standardize artifact output for `revivial/runtime/bin`.

## Phase 4: Service Observability

- Add structured logs and basic health endpoints for service processes.
- Add startup dependency checks to fail fast on missing DB/config.
- Add minimal metrics for connection/session/service health.

## Constraints

- Preserve network/protocol compatibility while clients are still legacy.
- Coordinate any protocol-impacting change with `medusa/revivial/MODERNIZATION_PLAN.md`.
