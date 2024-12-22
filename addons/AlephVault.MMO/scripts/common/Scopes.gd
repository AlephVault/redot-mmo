class_name AVMMOScopes

## Defines the macro-types for scopes. This is
## about structures and life-cycles of scopes,
## rather than their implementations.
enum ScopeType {
	## Scopes that are defined on server startup.
	## These scopes cannot be unloaded or undefined
	## until the server is stopped.
	DEFAULT=0,
	## Scopes that are defined/loaded on demand, and
	## are unloaded on demand as well. Remaining ones
	## are unloaded when the server is stopped.
	DYNAMIC=1,
	## Special scopes. They don't have any associated
	## actual object but represent some sort of state
	## deemed intermediate / non-playing (e.g. limbo,
	## choosing account, ...).
	SPECIAL=2
}

## Computes a final scope id, given the partial id and
## the scope type.
static func make_fq_scope_id(id: int, scope_type: ScopeType) -> int:
	if id < 0 || id >= (1 << 30):
		return -1
	if not ScopeType.has(scope_type):
		return -1
	return int(scope_type) << 30 || id

## Computes a final default scope id, given the partial id.
static func make_fq_default_scope_id(id: int) -> int:
	return make_fq_scope_id(id, ScopeType.DEFAULT)

## Computes a final dynamic scope id, given the partial id.
static func make_fq_dynamic_scope_id(id: int) -> int:
	return make_fq_scope_id(id, ScopeType.DYNAMIC)

## Computes a final scpecial scope id, given the partial id.
static func make_fq_special_scope_id(id: int) -> int:
	return make_fq_scope_id(id, ScopeType.SPECIAL)

## Unpacks a final scope id into its sub-id and type.
static func unpack_scope_id(id: int) -> Dictionary:
	if id < 0:
		return {}
	return {"id": id & ((1 << 30) - 1), "type": ScopeType.get(id >> 30)}