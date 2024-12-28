extends Node
## This is a base MMO Server node. Everything will occur
## right below this class related to MMO games.

func _ready() -> void:
	# Create the world (attach it with ownership).
	var world = AVMMOServerWorld.new()
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
	var connections = AVMMOServerConnections.new()
	connections.name = "Connections"
	add_child(connections, true)
	_connections = connections
	
	request_ready()

func _exit_tree() -> void:
	stop()
	
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

## The signal triggered when the server starts.
signal server_started

## The signal triggered when the server is stopped.
signal server_stopped

## The signal triggered when a client entered.
signal client_entered(id: int)

## The signal triggered when a client left.
signal client_left(id: int)

## Triggered when a scope is changed for a connection.
## With (-1) for the scope, it means complete removal.
signal scope_changed(connection_id: int, current_scope_id: int, scope_id: int)

# The current address from the current launch.
var _address: String

# The current port from the current launch.
var _port: int

# The world.
var _world: AVMMOServerWorld

## The world created for this server.
var world: AVMMOServerWorld:
	get:
		return _world
	set(value):
		assert(false, "The server's world cannot be set this way")

# The spawner.
var _spawner: MultiplayerSpawner

## The spawner created for this client.
var spawner: MultiplayerSpawner:
	get:
		return _spawner
	set(value):
		assert(false, "The server's spawner cannot be set this way")

# The parent of the connections.
var _connections: AVMMOServerConnections

## The parent of the connections.
var connections: AVMMOServerConnections:
	get:
		return _connections
	set(value):
		assert(false, "The server's connections cannot be set this way")

## The current address from the current launch.
var address: String:
	get:
		return _address
	set(value):
		assert(false, "The server's address cannot be set this way")

## The current port from the current launch.
var port: int:
	get:
		return _port
	set(value):
		assert(false, "The server's port cannot be set this way")

## Launches a server.
##
## All the parameters are forwarded to set_bind_ip
## or create_server, respectively.
func launch(
	port: int, max_clients: int = 4095, max_channels: int = 0,
	in_bandwidth: int = 0, out_bandwidth: int = 0
) -> Error:
	"""
	Launches a server.
	
	All the parameters are forwarded to set_bind_ip
	or create_server, respectively.
	"""
	
	var peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(
		port, max_clients, max_channels, in_bandwidth,
		out_bandwidth
	)
	if err != OK:
		return err
	_address = address
	_port = port
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	server_started.emit()
	return OK

## Stops a server.
##
## Returns true if the server could be stopped, or false if it could not.
func stop() -> bool:
	"""
	Stops a server.
	"""
	
	if is_instance_valid(multiplayer.multiplayer_peer) && multiplayer.is_server():
		_address = ""
		_port = 0
		# multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		server_stopped.emit()
		return true
	return false

## The server connection class for this server.
## This method should be overridden.
func connection_class() -> Script:
	return AVMMOServerConnection

func _on_peer_connected(id: int):
	if id != 1:
		client_entered.emit(id)

func _on_peer_disconnected(id: int):
	if id != 1:
		client_left.emit(id)
