extends Node

class_name AVMMOServer

## The signal triggered when the server starts.
signal server_started

## The signal triggered when the server is stopped.
signal server_stopped

## The signal triggered when a client entered.
signal client_entered(id: int)

## The signal triggered when a client left.
signal client_left(id: int)

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

## Launches a server.
##
## All the parameters are forwarded to set_bind_ip
## or create_server, respectively.
func launch(
	port: int, max_clients: int = 4096, max_channels: int = 0,
	in_bandwidth: int = 0, out_bandwidth: int = 0, address: String = "*"
) -> Error:
	"""
	Launches a server.
	
	All the parameters are forwarded to set_bind_ip
	or create_server, respectively.
	"""
	
	var peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(address)
	var err: Error = peer.create_server(
		port, max_clients, max_clients,
		in_bandwidth, out_bandwidth
	)
	if err != null:
		return err
	multiplayer.multiplayer_peer = peer
	_address = address
	_port = port
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return OK

## Stops a server.
##
## Returns true if the server could be stopped, or false if it could not.
func stop() -> bool:
	"""
	Stops a server.
	"""
	
	if multiplayer.is_server():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		_address = ""
		_port = 0
		server_stopped.emit()
		return true
	return false

func _on_peer_connected(id: int):
	if id == 1:
		server_started.emit()
	else:
		client_entered.emit(id)

func _on_peer_disconnected(id: int):
	if id != 1:
		client_left.emit(id)
