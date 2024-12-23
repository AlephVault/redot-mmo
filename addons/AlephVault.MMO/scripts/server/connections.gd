extends Node

class_name AVMMOServerConnections

## Triggered when a scope is changed for a connection.
## With (-1) for the scope, it means complete removal.
signal scope_changed(connection_id: int, scope_id: int)

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

func _enter_tree() -> void:
	var parent = get_parent()
	if parent is AVMMOServer:
		var server = parent as AVMMOServer
		if not server.client_entered.is_connected(_on_client_entered):
			server.client_entered.connect(_on_client_entered)
		if not server.client_left.is_connected(_on_client_left):
			server.client_left.connect(_on_client_left)

func _exit_tree() -> void:
	var parent = get_parent()
	if parent is AVMMOServer:
		var server = parent as AVMMOServer
		if server.client_entered.is_connected(_on_client_entered):
			server.client_entered.disconnect(_on_client_entered)
		if server.client_left.is_connected(_on_client_left):
			server.client_left.disconnect(_on_client_left)

func _on_client_entered(id: int) -> void:
	_add_client(id)

func _on_client_left(id: int) -> void:
	_remove_client(id)

func _init():
	_add_special_scope(AVMMOScopes.SCOPE_LIMBO)
	_add_special_scope(AVMMOScopes.SCOPE_ACCOUNT_DASHBOARD)

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
	assert(connection_id > 1, "The id of the connection must be > 1")
	assert(scope_id >= 0, "The id of the scope to assign must be > 0")
	if connection_id <= 1 or scope_id < 0:
		return
	_unset_connection_scope(connection_id)
	_set_connection_scope(connection_id, scope_id)
	var node: AVMMOServerConnection = get_connection_node(connection_id)
	if node:
		node.scope_changed.emit(scope_id)
		scope_changed.emit(node.id, scope_id)
		node.notifications.set_scope(scope_id)

## Tells whether the connection is registered here.
func has_connection(connection_id: int) -> bool:
	return _connections.has(connection_id)

## Returns all the connection ids.
func get_connections() -> Array[int]:
	return _connections.keys()

## Returns a given connection node.
func get_connection_node(id: int) -> AVMMOServerConnection:
	return get_node("Connection.%d" % id)

## Tells whether the scope is registered here. Actually,
## it only tells whether the scope exists AND has any
## connection on it.
func has_scope(scope_id: int) -> bool:
	return _scopes.has(scope_id)

# Adds a new connection object for the given
# connection id.
func _add_client(id: int) -> AVMMOServerConnection:
	assert(id > 1, "The id of the connection must be > 1")
	if id <= 1:
		return null
	# Create the node.
	var node = connection_class.new()
	node.name = "Connection.%s" % id 
	node.id = id
	set_connection_scope(id, AVMMOScopes.make_fq_special_scope_id(AVMMOScopes.SCOPE_LIMBO))
	add_child(node, true)
	
	# Return the node.
	return node

# Removes a client connection object for the
# given connection id.
func _remove_client(id: int):
	# Remove the node.
	var node = get_node("Connection.%s" % id)
	if node:
		_unset_connection_scope(id)
		node.scope_changed.emit(-1)
		scope_changed.emit(node.id, -1)
		remove_child(node)
