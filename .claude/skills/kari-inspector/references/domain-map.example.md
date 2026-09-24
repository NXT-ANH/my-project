# Domain module map (example)

> **Project file:** copy this to **`.inspector/domain-map.md`** at the product repo root and fill it in.
> Kit rules stay project-agnostic; **this file** holds confirmed business chains for *this* product only.
> Do not paste another project's modules here.

## Modules

List product modules / major screens (names as in SRS / UI):

| Order hint | Module / screen | Notes |
|------------|-----------------|-------|
| 1 | *(e.g. ModuleA)* | |
| 2 | *(e.g. ModuleB)* | depends on … |

## Primary business chains

Ordered journeys used when authoring **System Test** (`system_test`). One chain per bullet:

- `ModuleA → ModuleB → ModuleC` — *(short description of the business process)*
- …

## Confirmed

| Chain id / name | Confirmed by | Date | Notes |
|-----------------|--------------|------|-------|
| | | | |

When `inspector-gen-test` authors ST and the ticket matches a **Confirmed** chain, reuse it (log assumption)
instead of re-asking every time. Re-confirm when SRS changes the dependency order.
