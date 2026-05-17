# AlephVault.MMO.Common

Shared MMO data and helpers used by both the client and server packages.

This package exposes the global namespace `AlephVault__MMO__Common`.

## Public API

- `AlephVault__MMO__Common.Scopes`: helpers and constants for scope ids.
- `AlephVault__MMO__Common.ProtocolUtils`: helpers for protocols.

## Scopes

Scopes group connections into logical places such as rooms, channels, maps, or
intermediate states. The server owns scope assignment and clients mirror the
scope value reported by the server.

There are three scope types:

- `ScopeType.DEFAULT`: scopes that exist for the whole server lifetime.
- `ScopeType.DYNAMIC`: scopes that are loaded or unloaded on demand.
- `ScopeType.SPECIAL`: non-playing states such as limbo or account selection.

Two special scope constants are provided:

- `SCOPE_LIMBO`: the initial state for a newly created connection.
- `SCOPE_ACCOUNT_DASHBOARD`: a suggested state for logged-in users that still
  need to pick or create a playable profile.

Create full scope ids through `AlephVault__MMO__Common.Scopes`:

```gdscript
const Scopes = AlephVault__MMO__Common.Scopes

const LIMBO = Scopes.make_fq_special_scope_id(Scopes.SCOPE_LIMBO)
const GENERAL = Scopes.make_fq_default_scope_id(0)
const ROOM = Scopes.make_fq_dynamic_scope_id(15)
```

Use `unpack_scope_id(scope_id)` to recover the relative id and scope type.

## Protocol Utils

This class has many utilities related to protocols management.

- `ProtocolUtils.sort_by_dependencies(dependencies, parent_type)` returns a new
  array sorted from the least dependent protocol class to the most dependent one.
  Each script in `dependencies` must extend `parent_type`, and `parent_type` must
  define a static `dependencies: Array[Script]` property. Invalid inputs, missing
  dependencies, and circular dependencies emit an error and return an empty array.

## Related Packages

- [AlephVault.MMO.Client](../AlephVault.MMO.Client/README.md) uses these scope
  ids to mirror the server-assigned state for the current client connection.
- [AlephVault.MMO.Server](../AlephVault.MMO.Server/README.md) uses these scope
  ids to group and iterate connections.
