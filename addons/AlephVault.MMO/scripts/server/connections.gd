extends Node

func add_special_scope(id: int) -> Dictionary:
	id = AlephVault__MMO.Common.Scopes.make_fq_special_scope_id(id)
	if _scopes.has(id):
		return _scopes[id]
	else:
		var scope: Dictionary = {}
		_scopes[id] = scope
		return scope

func _enter_tree() -> void:
	var parent = get_parent()
	if parent is AlephVault__MMO.Server.Main:
		var server = parent as AlephVault__MMO.Server.Main
		if not server.client_entered.is_connected(_on_client_entered):
			server.client_entered.connect(_on_client_entered)
		if not server.client_left.is_connected(_on_client_left):
			server.client_left.connect(_on_client_left)

func _exit_tree() -> void:
	var parent = get_parent()
	if parent is AlephVault__MMO.Server.Main:
		var server = parent as AlephVault__MMO.Server.Main
		if server.client_entered.is_connected(_on_client_entered):
			server.client_entered.disconnect(_on_client_entered)
		if server.client_left.is_connected(_on_client_left):
			server.client_left.disconnect(_on_client_left)

func _on_client_entered(id: int) -> void:
	_add_client(id)

func _on_client_left(id: int) -> void:
	_remove_client(id)

func _init():
	add_special_scope(AlephVault__MMO.Common.Scopes.SCOPE_LIMBO)
	add_special_scope(AlephVault__MMO.Common.Scopes.SCOPE_ACCOUNT_DASHBOARD)

# The connections will be kept here.
var _connections: Dictionary = {
	# connection_id: {
	#     node, scope_id
	# }; The id can be any default, dynamic or special scope id.
}

# The scopes and their connections will be kept here.
var _scopes: Dictionary = {
	# scope_id: Dictionary[connection_id -> true].
}

func _set_scope_for_connection(connection_id: int, scope_id: int):
	_connections[connection_id] = {
		"scope_id": scope_id,
		"node": get_node("Connection_%d" % connection_id)
	}

func _unset_scope_for_connection(connection_id: int):
	if _connections.has(connection_id):
		_connections.erase(connection_id)

func _set_connection_into_scope(connection_id: int, scope_id: int):
	if not _scopes.has(scope_id):
		_scopes[scope_id] = {}
	_scopes[scope_id][connection_id] = true

func _unset_connection_from_scope(connection_id: int):
	if _connections.has(connection_id):
		var scope_id = _connections[connection_id]["scope_id"]
		if _scopes.has(scope_id):
			var scope = _scopes[scope_id]
			if scope.has(connection_id):
				scope.erase(connection_id)
			if len(scope) == 0 and AlephVault__MMO.Common.Scopes.ScopeType.get(scope_id >> 30) != AlephVault__MMO.Common.Scopes.ScopeType.SPECIAL:
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
		var array: Array[int] = []
		array.assign(_scopes[scope_id].keys())
		return array
	else:
		return []

## Gets the scope for a connection.
func get_connection_scope(connection_id: int) -> int:
	if _connections.has(connection_id):
		return _connections[connection_id]["scope_id"]
	else:
		return -1

## Sets the scope for a connection.
func set_connection_scope(connection_id: int, scope_id: int):
	assert(connection_id > 1, "The id of the connection must be > 1")
	assert(scope_id >= 0, "The id of the scope to assign must be > 0")
	if connection_id <= 1 or scope_id < 0:
		return
	var current_scope_id = get_connection_scope(connection_id)
	_unset_connection_scope(connection_id)
	_set_connection_scope(connection_id, scope_id)
	var node: AlephVault__MMO.Server.Connection = get_connection_node(connection_id)
	if node:
		node.scope_changed.emit(current_scope_id, scope_id)
		(get_parent() as AlephVault__MMO.Server.Main).scope_changed.emit(node.id, current_scope_id, scope_id)
		node.notifications.set_scope(scope_id)

## Tells whether the connection is registered here.
func has_connection(connection_id: int) -> bool:
	return _connections.has(connection_id)

## Returns all the connection ids.
func get_connections() -> Array[int]:
	var array: Array[int] = []
	array.assign(_connections.keys())
	return array

## Returns a given connection node.
func get_connection_node(id: int) -> AlephVault__MMO.Server.Connection:
	return _connections[id]["node"]

## Iterates over all the nodes in a scope. For each
## connection, executes the given callable.
func scope_iterate(scope_id: int, method: Callable):
	var connections = get_connections_in_scope(scope_id)
	if len(connections) == 0:
		return
	var scope = _scopes[scope_id]

	for id in connections:
		method.call(_connections[id]["node"])

## Tells whether the scope is registered here. Actually,
## it only tells whether the scope exists AND has any
## connection on it.
func has_scope(scope_id: int) -> bool:
	return _scopes.has(scope_id)

# Adds a new connection object for the given
# connection id.
func _add_client(id: int) -> AlephVault__MMO.Server.Connection:
	assert(id > 1, "The id of the connection must be > 1")
	if id <= 1:
		return null
	# Create the node.
	var node = (get_parent() as AlephVault__MMO.Server.Main).connection_class().new()
	var inherits: bool = node is AlephVault__MMO.Server.Connection
	assert(inherits, "The assigned connection class must inherit AlephVault__MMO.Server.Connection")
	if inherits:
		node.name = "Connection_%s" % id 
		node.id = id
		set_connection_scope(id, AlephVault__MMO.Common.Scopes.make_fq_special_scope_id(AlephVault__MMO.Common.Scopes.SCOPE_LIMBO))
		print("[AlephVault.MMO:Server] Adding Connection to: " + String(get_path()) + ":", node)
		add_child(node, true)
		node.init_authority()
		return node
	return null

# Removes a client connection object for the
# given connection id.
func _remove_client(id: int):
	# Remove the node.
	var node = get_node("Connection_%s" % id)
	if node:
		_unset_connection_scope(id)
		node.scope_changed.emit(-1)
		(get_parent() as AlephVault__MMO.Server.Main).scope_changed.emit(node.id, -1)
		remove_child(node)
