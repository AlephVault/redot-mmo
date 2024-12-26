extends Node

class_name AVMMOClient

func _ready() -> void:
	# Create the world (attach it with ownership).
	var world = AVMMOClientWorld.new()
	world.name = "World"
	add_child(world, true)
	world.owner = self
	_world = world

	# Create the spawner (attach it with ownership).
	var spawner = MultiplayerSpawner.new()
	spawner.name = "MultiplayerSpawner"
	add_child(spawner, true)
	spawner.owner = self
	_spawner = spawner

	# Set, in the spawner, the spawn path to the world.
	_spawner.spawn_path = _world.get_path()

	# Also, set a place for the child connections.
	var connections = AVMMOClientConnections.new()
	connections.name = "Connections"
	add_child(connections, true)
	_connections = connections

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
var _world: AVMMOClientWorld

## The world created for this client.
var world: AVMMOClientWorld:
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

# The parent of the connections.
var _connections: AVMMOClientConnections

## The parent of the connections.
var connections: AVMMOClientConnections:
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
	return AVMMOClientConnection

func _on_connected_to_server():
	client_started.emit()

func _on_server_disconnected():
	client_stopped.emit()

func _on_connection_failed():
	_address = ""
	_port = 0
	client_failed.emit()
