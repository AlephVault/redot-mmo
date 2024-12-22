extends Node

class_name AVMMOServerConnections

## The "LIMBO" special scope. Used for just-created
## connections or when a connection is popped from
## another scope with no explicit relocation.
const SCOPE_LIMBO: int = 0

## The "ACCOUNT_DASHBOARD" special scope. Suggested
## for when a connection is established / logged in
## but no playable state or profile was initialized.
## An example is for games where accounts have more
## than one profile (ej. multi-character accounts)
## and players have to pick a profile or create one
## in order to start playing.
const SCOPE_ACCOUNT_DASHBOARD: int = 1

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
static func make_fq_special_Scope_id(id: int) -> int:
	return make_fq_scope_id(id, ScopeType.SPECIAL)

func _inherits_native_class(script: Script, native_class_name: String) -> bool:
	# If the script's top-level extends statement is "extends Node",
	# script.native_class == "Node"
	if script.native_class == native_class_name:
		return true
	var parent = script.get_base_script()
	if parent:
		return _inherits_native_class(parent, native_class_name)
	return false

## The class of connections to instantiate when a connection is
## established.
var connection_class: Script = AVMMOServerConnection:
	set(value):
		var inherits: bool = _inherits_native_class(value, "AVMMOServerConnection")
		assert(inherits, "The assigned connection class must inherit AVMMOServerConnection")
		if inherits:
			connection_class = value

func _add_special_scope(id: int) -> Dictionary:
	if _scopes.has(id):
		return _scopes[id]
	else:
		var scope: Dictionary = {}
		_scopes[id] = scope
		return scope

func _init():
	_add_special_scope(SCOPE_LIMBO)
	_add_special_scope(SCOPE_ACCOUNT_DASHBOARD)

# The connections will be kept here.
var _connections: Dictionary = {
	# connection_id: scope_id; The id can be any default, dynamic or special scope id.
}

# The scopes and their connections will be kept here.
var _scopes: Dictionary = {
	# scope_id: Dictionary[connection_id -> true].
}

## Adds a new connection object for the given
## connection id.
func add_client(id: int) -> AVMMOServerConnection:
	# Create the node.
	var node = AVMMOServerConnection.new()
	node.name = "Connection.%s" % id
	node.id = id
	add_child(node, true)
	
	# Return the node.
	return node
