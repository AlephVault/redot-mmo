# AlephVault.MMO.Common

Shared MMO data and helpers used by both the client and server packages.

This package exposes the global namespace `AlephVault__MMO__Common`.

## Public API

- `AlephVault__MMO__Common.Scopes`: helpers and constants for scope ids.
- `AlephVault__MMO__Common.ProtocolUtils`: helpers for protocols.
- `AlephVault__MMO__Common.Encoding`: MessagePack encoding helpers and
  higher-level Godot Variant codec support.

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

## Encoding

The encoding package contains two layers:

- `AlephVault__MMO__Common.Encoding.MessagePack`: a low-level MessagePack
  implementation.
- `AlephVault__MMO__Common.Encoding.Codec`: a higher-level codec that normalizes
  Godot-specific Variant values before MessagePack encoding and restores them when
  a target type is provided.

### Public Functions

Low-level MessagePack functions:

```gdscript
const MessagePack = AlephVault__MMO__Common.Encoding.MessagePack

var encoded := MessagePack.encode({"scope": "main", "players": 12})
if encoded.status == null or encoded.status == OK:
	var decoded := MessagePack.decode(encoded.value)
```

- `MessagePack.encode(value: Variant) -> Dictionary` returns
  `{ "status": error_or_null, "value": PackedByteArray }`.
- `MessagePack.decode(bytes: PackedByteArray) -> Dictionary` returns
  `{ "status": error_or_null, "value": Variant }`.

High-level codec functions:

```gdscript
const Codec = AlephVault__MMO__Common.Encoding.Codec

var codec := Codec.new()
var encoded := codec.encode(Vector3(1, 2, 3))
if encoded.status == null or encoded.status == OK:
	var decoded := codec.decode(encoded.value, TYPE_VECTOR3)
	if decoded.status == OK:
		var value: Vector3 = decoded.value
```

- `encode(value: Variant) -> Dictionary` normalizes the value and encodes it as
  MessagePack bytes.
- `decode(value: PackedByteArray, type_: Variant) -> Dictionary` decodes
  MessagePack bytes and restores the result as `type_`.
- `type_` can be a `TYPE_*` constant, a `Script`, or an object instance whose
  script should be used as the target object type.

### Supported Types

`MessagePack` directly supports:

- `null`, `bool`, `int`, `float`, and `String`.
- `Array` and `Dictionary`, recursively.
- `PackedByteArray`, encoded as MessagePack binary data.

The higher-level codec additionally supports:

- Godot math and geometry values: `Vector2`, `Vector2i`, `Rect2`, `Rect2i`,
  `Vector3`, `Vector3i`, `Transform2D`, `Vector4`, `Vector4i`, `Plane`,
  `Quaternion`, `AABB`, `Basis`, `Transform3D`, `Projection`, and `Color`.
- `StringName` and `NodePath`, normalized as strings and restored when the
  matching target type is requested.
- `Dictionary` and `Array`, including nested values.
- Packed arrays: byte, int32, int64, float32, float64, string, vector2,
  vector3, vector4, and color arrays.
- Scripted `Object` instances that are not `Node` or `Resource`. Stored
  properties are encoded by name and restored into a new instance of the target
  script.

### Caveats

- The codec normalizes Godot-specific values into MessagePack-compatible
  arrays, dictionaries, strings, numbers, booleans, and nulls. Decoding without
  the right target type can lose the original Godot type. For example, a
  `Vector3` decodes as an array unless `TYPE_VECTOR3` is requested.
- Packed arrays normalize as regular arrays. They are restored only when the
  packed array `TYPE_*` constant is supplied to `decode`.
- `StringName`, `NodePath`, and `RID` normalize as strings. `StringName` and
  `NodePath` can be restored by target type, but `RID` cannot be reconstructed.
- Dictionary keys are normalized too. Keys whose original types normalize to the
  same value can collide or come back with a different type unless decoded into
  a typed object/property.
- `Callable`, `Signal`, `Node`, and `Resource` values are not supported.
- Object encoding only includes properties with `PROPERTY_USAGE_STORAGE`.
  Unknown decoded fields are ignored, and missing fields keep the script
  instance defaults.
- Typed object and typed array restoration depends on Godot exposing enough
  property metadata, class names, or script paths for the codec to resolve the
  target script and element type.
- MessagePack extension types are not implemented by the low-level decoder.
- Low-level MessagePack floats are written as 32-bit floats, so values may lose
  precision compared to Godot's default float representation.
  - This might be changed in the future, for this implementation of MsgPack.

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
