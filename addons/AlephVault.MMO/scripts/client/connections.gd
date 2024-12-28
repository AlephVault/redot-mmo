extends Node

# The connections will be kept here. Actually, only
# one connection will belong here.
var _connections: Dictionary = {}

func _enter_tree() -> void:
	var parent = get_parent()
	if parent is AlephVault__MMO.Client.Main:
		var client = parent as AlephVault__MMO.Client.Main
		if not client.client_started.is_connected(_on_client_started):
			client.client_started.connect(_on_client_started)
		if not client.client_stopped.is_connected(_on_client_stopped):
			client.client_stopped.connect(_on_client_stopped)

func _exit_tree() -> void:
	var parent = get_parent()
	if parent is AlephVault__MMO.Client.Main:
		var client = parent as AlephVault__MMO.Client.Main
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
func _add_client() -> AlephVault__MMO.Client.Connection:
	# Create the node.
	var node = (get_parent() as AlephVault__MMO.Client.Main).connection_class().new()
	var inherits: bool = node is AlephVault__MMO.Client.Connection
	assert(inherits, "The assigned connection class must inherit AlephVault__MMO.Client.Connection")
	if inherits:
		var id = multiplayer.get_unique_id()
		node.name = "Connection_%s" % id
		node.id = id
		add_child(node, true)
		node.init_authority()
		return node
	return null

## Returns the only client connection object.
func get_connection_node() -> AlephVault__MMO.Client.Connection:
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
