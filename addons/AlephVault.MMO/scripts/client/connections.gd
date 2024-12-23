extends Node

class_name AVMMOClientConnections

# The connections will be kept here. Actually, only
# one connection will belong here.
var _connections: Dictionary = {}

## The class of connections to instantiate when a connection is
## established.
var connection_class: Script = AVMMOClientConnection:
	set(value):
		var inherits: bool = AVMMOClasses.inherits_native_class(value, "AVMMOClientConnection")
		assert(inherits, "The assigned connection class must inherit AVMMOClientConnection")
		if inherits:
			connection_class = value

func _enter_tree() -> void:
	var parent = get_parent()
	if parent is AVMMOClient:
		var client = parent as AVMMOClient
		if not client.client_started.is_connected(_on_client_started):
			client.client_started.connect(_on_client_started)
		if not client.client_stopped.is_connected(_on_client_stopped):
			client.client_stopped.connect(_on_client_stopped)

func _exit_tree() -> void:
	var parent = get_parent()
	if parent is AVMMOClient:
		var client = parent as AVMMOClient
		if client.client_started.is_connected(_on_client_started):
			client.client_started.disconnect(_on_client_started)
		if client.client_stopped.is_connected(_on_client_stopped):
			client.client_stopped.disconnect(_on_client_stopped)

func _on_client_started() -> void:
	_add_client()

func _on_client_stopped() -> void:
	_remove_client()

# Adds a new connection object for the current
# connection id. It will be the only one here.
func _add_client() -> AVMMOClientConnection:
	# Create the node.
	var node = connection_class.new()
	var id = multiplayer.get_unique_id()
	node.name = "Connection.%s" % id
	node.id = id
	add_child(node, true)
	
	# Return the node.
	return node

## Returns the only client connection object.
func get_connection_node() -> AVMMOClientConnection:
	return get_child(0)

# Removes a client connection object for the
# given connection id.
func _remove_client():
	# Remove the node. It will be only one single
	# child, and the id might not be THAT retrievable
	# because by this point the connection might be
	# terminated.
	var node = get_connection_node()
	if node:
		remove_child(node)
