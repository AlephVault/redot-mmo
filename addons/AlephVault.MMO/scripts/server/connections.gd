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
static func make_fq_special_scope_id(id: int) -> int:
	return make_fq_scope_id(id, ScopeType.SPECIAL)

## Unpacks a final scope id into its sub-id and type.
static func unpack_scope_id(id: int) -> Dictionary:
	if id < 0:
		return {}
	return {"id": id & ((1 << 30) - 1), "type": ScopeType.get(id >> 30)}

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

func _set_scope_for_connection(connection_id: int, scope_id: int):
	_connections[connection_id] = scope_id

func _unset_scope_for_connection(connection_id: int):
	if _connections.has(connection_id):
		_connections.erase(connection_id)

func _set_connection_into_scope(connection_id: int, scope_id: int):
	if not _scopes.has(scope_id):
		_scopes[scope_id] = {}
	_scopes[scope_id][connection_id] = true

func _unset_connection_from_scope(connection_id: int):
	if _connections.has(connection_id):
		var scope_id = _connections[connection_id]
		if _scopes.has(scope_id):
			var scope = _scopes[scope_id]
			if scope.has(connection_id):
				scope.erase(connection_id)
			if len(scope) == 0:
				_scopes.erase(scope_id)

func _unset_connection_scope(connection_id: int):
	_unset_connection_from_scope(connection_id)
	_unset_scope_for_connection(connection_id)

func _set_connection_scope(connection_id: int, scope_id: int):
	_set_scope_for_connection(connection_id, scope_id)
	_set_connection_into_scope(connection_id, scope_id)

## Gets the connections inside that scope.
func get_connections_in_scope(scope_id: int) -> Array[int]:
	if _scopes.has(scope_id):
		return _scopes.keys()
	else:
		return []

## Gets the scope for a connection.
func get_connection_scope(connection_id: int) -> int:
	if _connections.has(connection_id):
		return _connections[connection_id]
	else:
		return -1

## Sets the scope for a connection.
func set_connection_scope(connection_id: int, scope_id: int):
	var has_connection = _connections.has(connection_id)
	var has_scope = _scopes.has(scope_id)

	assert(has_connection, "The connection does not exist")
	assert(has_scope, "The scope does not exist")

	if has_connection and has_scope:
		_unset_connection_scope(connection_id)
		_set_connection_scope(connection_id, scope_id)

## Tells whether the connection is registered here.
func has_connection(connection_id: int) -> bool:
	return _connections.has(connection_id)

## Tells whether the scope is registered here. Actually,
## it only tells whether the scope exists AND has any
## connection on it.
func has_scope(scope_id: int) -> bool:
	return _scopes.has(scope_id)

## Adds a new connection object for the given
## connection id.
func add_client(id: int) -> AVMMOServerConnection:
	# Create the node.
	var node = connection_class.new()
	node.name = "Connection.%s" % id
	node.id = id
	_set_connection_scope(id, make_fq_special_scope_id(SCOPE_LIMBO))
	add_child(node, true)
	
	# Return the node.
	return node

## Removes a client connection object for the
## given connection id.
func remove_client(id: int):
	# Remove the node.
	var node = get_node("Connection.%s" % id)
	_unset_connection_scope(id)
	remove_child(node)
