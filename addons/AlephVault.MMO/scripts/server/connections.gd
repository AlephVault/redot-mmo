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

## The class of connections to instantiate when a connection is
## established.
var connection_class: Script = AVMMOServerConnection:
	set(value):
		var inherits: bool = AVMMOClasses.inherits_native_class(value, "AVMMOServerConnection")
		assert(inherits, "The assigned connection class must inherit AVMMOServerConnection")
		if inherits:
			connection_class = value

func _add_special_scope(id: int) -> Dictionary:
	id = AVMMOScopes.make_fq_special_scope_id(id)
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
			if len(scope) == 0 and AVMMOScopes.ScopeType.get(scope_id >> 30) != AVMMOScopes.ScopeType.SPECIAL:
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
		var node: AVMMOServerConnection = _get_connection_node(connection_id)
		if node:
			node.scope_changed.emit(scope_id)
			node.notifications.set_scope(scope_id)


## Tells whether the connection is registered here.
func has_connection(connection_id: int) -> bool:
	return _connections.has(connection_id)

func _get_connection_node(id: int) -> AVMMOServerConnection:
	return get_node("Connection.%d" % id)

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
	_set_connection_scope(id, AVMMOScopes.make_fq_special_scope_id(SCOPE_LIMBO))
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
