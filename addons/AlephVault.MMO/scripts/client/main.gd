extends Node

class_name AVMMOClient

func _init() -> void:
	var spawner = MultiplayerSpawner.new()
	spawner.name = "MultiplayerSpawner"
	add_child(spawner, true)

## The signal triggered when the client connected to a server.
signal client_started

## The signal triggered when the client disconnected from a server.
signal client_stopped

# The current address from the current launch.
var _address: String

# The current port from the current launch.
var _port: int

## The current address from the current launch.
var address: String:
	get:
		return _address

## The current port from the current launch.
var port: int:
	get:
		return _port

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
		address, port, channel_count,
		in_bandwidth, out_bandwidth, local_port
	)
	if err != null:
		return err
	multiplayer.multiplayer_peer = peer
	_address = address
	_port = port
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	return OK

## Leaves the current server.
##
## Returns true if the client could be stopped, or false if it could not.
func leave_server() -> bool:
	"""
	Leaves the server (stops the client).
	"""

	if multiplayer.is_server():
		return false

	if not multiplayer.has_multiplayer_peer():
		return false
	
	var status: MultiplayerPeer.ConnectionStatus = multiplayer.multiplayer_peer.get_connection_status()
	if status != MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
		return false
		
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	_address = ""
	_port = 0
	return true

func _on_connected_to_server():
	client_started.emit()

func _on_server_disconnected():
	client_stopped.emit()

func _on_connection_failed():
	_address = ""
	_port = 0
