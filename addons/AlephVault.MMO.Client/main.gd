extends Node

func _ready() -> void:
	# First, take all the nodes that are Protocol instances.
	var protocol_nodes := _take_protocol_nodes()

	# Create the world (attach it with ownership).
	var world = AlephVault__MMO__Client.World.new()
	world.name = "World"
	print("[AlephVault.MMO:Client] Adding World to: " + String(get_path()) + ":", world)
	add_child(world, true)
	world.owner = self
	_world = world

	# Create the spawner (attach it with ownership).
	var spawner = MultiplayerSpawner.new()
	spawner.name = "MultiplayerSpawner"
	print("[AlephVault.MMO:Client] Adding MultiplayerSpawner to: " + String(get_path()) + ":", spawner)
	add_child(spawner, true)
	spawner.owner = self
	_spawner = spawner

	# Set, in the spawner, the spawn path to the world.
	_spawner.spawn_path = _world.get_path()

	# Also, set a place for the protocols.
	var protocols = AlephVault__MMO__Client.Protocols.new()
	protocols.name = "Protocols"
	print("[AlephVault.MMO:Client] Adding Protocols to: " + String(get_path()) + ":", protocols)
	add_child(protocols, true)
	_protocols = protocols

	# Add all Protocol nodes before Connections can react to connection signals.
	_add_sorted_protocol_nodes(protocol_nodes)

	# Also, set a place for the child connections.
	var connections = AlephVault__MMO__Client.Connections.new()
	connections.name = "Connections"
	print("[AlephVault.MMO:Client] Adding Connections to: " + String(get_path()) + ":", connections)
	add_child(connections, true)
	_connections = connections

	_connect_protocol_hooks()

	request_ready()

func _exit_tree() -> void:
	leave_server()

	# Remove the world.
	if _world != null:
		remove_child(_world)
		_world.queue_free()
		_world = null
	
	# Remove the spawner.
	if _spawner != null:
		remove_child(_spawner)
		_spawner.queue_free()
		_spawner = null

	# Remove the protocols.
	if _protocols != null:
		_disconnect_protocol_hooks()
		_restore_protocol_nodes()
		remove_child(_protocols)
		_protocols.queue_free()
		_protocols = null

	# Remove the connections.
	if _connections != null:
		remove_child(_connections)
		_connections.queue_free()
		_connections = null

## The signal triggered when the client connected to a server.
signal client_started

## The signal triggered when the client disconnected from a server.
signal client_stopped

## The signal triggered when the client failed to connect to a server.
signal client_failed

## Triggered when a scope is changed for a connection.
## With (-1) for the scope, it means complete removal.
signal scope_changed(current_scope_id: int, scope_id: int)

# The current address from the current launch.
var _address: String

# The current port from the current launch.
var _port: int

# The world.
var _world: AlephVault__MMO__Client.World

## The world created for this client.
var world: AlephVault__MMO__Client.World:
	get:
		return _world
	set(value):
		assert(false, "The client's world cannot be set this way")

# The spawner.
var _spawner: MultiplayerSpawner

## The spawner created for this client.
var spawner: MultiplayerSpawner:
	get:
		return _spawner
	set(value):
		assert(false, "The client's spawner cannot be set this way")

# The parent of the protocols.
var _protocols: AlephVault__MMO__Client.Protocols

## The parent of the protocols.
var protocols: AlephVault__MMO__Client.Protocols:
	get:
		return _protocols
	set(value):
		assert(false, "The client's protocols cannot be set this way")

# The parent of the connections.
var _connections: AlephVault__MMO__Client.Connections

## The parent of the connections.
var connections: AlephVault__MMO__Client.Connections:
	get:
		return _connections
	set(value):
		assert(false, "The client's connections cannot be set this way")

## The current address from the current launch.
var address: String:
	get:
		return _address
	set(value):
		assert(false, "The client's address cannot be set this way")

## The current port from the current launch.
var port: int:
	get:
		return _port
	set(value):
		assert(false, "The client's port cannot be set this way")

func _take_protocol_nodes() -> Array[Node]:
	var protocol_nodes: Array[Node] = []
	for child in get_children():
		if _node_extends_protocol(child):
			remove_child(child)
			protocol_nodes.append(child)
	return protocol_nodes

func _add_sorted_protocol_nodes(protocol_nodes: Array[Node]) -> void:
	var protocol_classes: Array[Script] = []
	for protocol_node in protocol_nodes:
		var protocol_class = protocol_node.get_script() as Script
		if protocol_class != null:
			protocol_classes.append(protocol_class)

	var sorted_protocol_classes = AlephVault__MMO__Common.ProtocolUtils.sort_by_dependencies(
		protocol_classes, AlephVault__MMO__Client.Protocol
	)
	for protocol_class in sorted_protocol_classes:
		for protocol_node in protocol_nodes:
			if protocol_node.get_parent() == null and protocol_node.get_script() == protocol_class:
				_protocols.add_child(protocol_node, true)
				break

	for protocol_node in protocol_nodes:
		if protocol_node.get_parent() == null:
			protocol_node.queue_free()

func _restore_protocol_nodes() -> void:
	for child in _protocols.get_children():
		if _node_extends_protocol(child):
			_protocols.remove_child(child)
			add_child(child, true)

func _connect_protocol_hooks() -> void:
	for child in _protocols.get_children():
		if _node_extends_protocol(child):
			var client_started_hook := Callable(child, "client_started")
			if not client_started.is_connected(client_started_hook):
				client_started.connect(client_started_hook)
			var client_stopped_hook := Callable(child, "client_stopped")
			if not client_stopped.is_connected(client_stopped_hook):
				client_stopped.connect(client_stopped_hook)

func _disconnect_protocol_hooks() -> void:
	for child in _protocols.get_children():
		if _node_extends_protocol(child):
			var client_started_hook := Callable(child, "client_started")
			if client_started.is_connected(client_started_hook):
				client_started.disconnect(client_started_hook)
			var client_stopped_hook := Callable(child, "client_stopped")
			if client_stopped.is_connected(client_stopped_hook):
				client_stopped.disconnect(client_stopped_hook)

func _node_extends_protocol(node: Node) -> bool:
	var script = node.get_script() as Script
	while script != null:
		if script == AlephVault__MMO__Client.Protocol:
			return true
		script = script.get_base_script()
	return false

## Joins a server.
##
## All the parameters are forwarded to create_client.
func join_server(
	address: String, port: int, channel_count: int = 0,
	in_bandwidth: int = 0, out_bandwidth: int = 0, local_port: int = 0
) -> Error:
	"""
	Joins a server.
	
	All the parameters are forwarded to create_client.
	"""

	var peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(
		address, port, channel_count, in_bandwidth, out_bandwidth, local_port
	)
	if err != OK:
		return err
	_address = address
	_port = port
	multiplayer.multiplayer_peer = peer
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	return OK

## Leaves the current server.
##
## Returns true if the client could be stopped, or false if it could not.
func leave_server() -> bool:
	"""
	Leaves the server (stops the client).
	"""

	if not is_instance_valid(multiplayer.multiplayer_peer) or multiplayer.is_server():
		return false

	if not multiplayer.has_multiplayer_peer():
		return false
		
	# multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	_address = ""
	_port = 0
	return true

## The client connection class for this client.
## This method should be overridden.
func connection_class() -> Script:
	return AlephVault__MMO__Client.Connection

func _on_connected_to_server():
	client_started.emit()

func _on_server_disconnected():
	client_stopped.emit()

func _on_connection_failed():
	_address = ""
	_port = 0
	client_failed.emit()
