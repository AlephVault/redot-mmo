extends Node

# The connections will be kept here. Actually, only
# one connection will belong here.
var _connections: Dictionary = {}

func _enter_tree() -> void:
	var parent = get_parent()
	if parent is AlephVault__MMO__Client.Main:
		var client = parent as AlephVault__MMO__Client.Main
		if not client.client_started.is_connected(_on_client_started):
			client.client_started.connect(_on_client_started)
		if not client.client_stopped.is_connected(_on_client_stopped):
			client.client_stopped.connect(_on_client_stopped)

func _exit_tree() -> void:
	var parent = get_parent()
	if parent is AlephVault__MMO__Client.Main:
		var client = parent as AlephVault__MMO__Client.Main
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
func _add_client() -> AlephVault__MMO__Client.Connection:
	_remove_client()
	# Create the node.
	var node = AlephVault__MMO__Client.Connection.new()
	var id = multiplayer.get_unique_id()
	node.name = "Connection_%s" % id
	node.id = id
	print("[AlephVault.MMO:Client] Adding Connection to: " + String(get_path()) + "/", node)
	add_child(node, true)
	(get_parent() as AlephVault__MMO__Client.Main).protocols.install(node)
	return node

## Returns the only client connection object.
func get_connection_node() -> AlephVault__MMO__Client.Connection:
	if get_child_count() == 0:
		return null
	return get_child(0)

# Removes a client connection object for the
# given connection id.
func _remove_client():
	# Remove all children so stale nodes from previous disconnect paths cannot
	# keep protocol commands bound to an old connection.
	for node in get_children():
		remove_child(node)
		node.queue_free()
