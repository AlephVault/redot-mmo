extends Node

func _ready() -> void:
	# First, take all the nodes that are Protocol instances.
	var protocol_nodes := _take_protocol_nodes()

	# Also, set a place for the protocols.
	var manager = AlephVault__MMO__Client.Protocols.Manager.new()
	manager.name = "Protocols"
	print("[AlephVault.MMO:Client] Adding Protocols to: " + String(get_path()) + ":", manager)
	add_child(manager, true)
	_protocols = manager

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

## The type of peer to create when joining a server.
@export var peer_type: AlephVault__MMO__Common.Setup.PeerType = AlephVault__MMO__Common.Setup.PeerType.ENET

## ENet channel count to use when joining a server.
@export var enet_channel_count: int = 0

## ENet inbound bandwidth limit to use when joining a server.
@export var enet_in_bandwidth: int = 0

## ENet outbound bandwidth limit to use when joining a server.
@export var enet_out_bandwidth: int = 0

## ENet local port to bind when joining a server.
@export var enet_local_port: int = 0

## Whether WebSocket connections should use wss:// instead of ws://.
@export var ws_secure: bool = false

## WebSocket path to append when address is not already a ws:// or wss:// URL.
@export var ws_path: String = "/"

## WebSocket protocols to offer during the handshake.
@export var ws_supported_protocols: PackedStringArray = PackedStringArray()

## WebSocket headers to include during the handshake.
@export var ws_handshake_headers: PackedStringArray = PackedStringArray()

## WebSocket handshake timeout in seconds.
@export var ws_handshake_timeout: float = 3.0

## WebSocket inbound buffer size.
@export var ws_inbound_buffer_size: int = 65535

## WebSocket outbound buffer size.
@export var ws_outbound_buffer_size: int = 65535

## WebSocket maximum queued packet count.
@export var ws_max_queued_packets: int = 4096

# The current address from the current launch.
var _address: String

# The current port from the current launch.
var _port: int

# The parent of the protocols.
var _protocols: AlephVault__MMO__Client.Protocols.Manager

## The parent of the protocols.
var protocols: AlephVault__MMO__Client.Protocols.Manager:
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
		protocol_classes, AlephVault__MMO__Client.Protocols.Protocol
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
		if script == AlephVault__MMO__Client.Protocols.Protocol:
			return true
		script = script.get_base_script()
	return false

## Joins a server.
##
## ENet-specific parameters override the exported enet_* properties when they
## are not -1. WebSocket parameters are read from exported ws_* properties.
func join_server(
	address: String, port: int, channel_count: int = -1,
	in_bandwidth: int = -1, out_bandwidth: int = -1, local_port: int = -1
) -> Error:
	"""
	Joins a server.
	
	ENet-specific parameters override the exported enet_* properties when they
	are not -1. WebSocket parameters are read from exported ws_* properties.
	"""

	var peer: MultiplayerPeer
	var err: Error
	match peer_type:
		AlephVault__MMO__Common.Setup.PeerType.ENET:
			peer = ENetMultiplayerPeer.new()
			err = _create_enet_client(
				peer, address, port, channel_count, in_bandwidth, out_bandwidth, local_port
			)
		AlephVault__MMO__Common.Setup.PeerType.WEBSOCKETS:
			peer = WebSocketMultiplayerPeer.new()
			err = _create_ws_client(peer, address, port)
		_:
			return ERR_INVALID_PARAMETER
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

func _create_enet_client(
	peer: ENetMultiplayerPeer, address: String, port: int, channel_count: int,
	in_bandwidth: int, out_bandwidth: int, local_port: int
) -> Error:
	return peer.create_client(
		address, port,
		enet_channel_count if channel_count == -1 else channel_count,
		enet_in_bandwidth if in_bandwidth == -1 else in_bandwidth,
		enet_out_bandwidth if out_bandwidth == -1 else out_bandwidth,
		enet_local_port if local_port == -1 else local_port
	)

func _create_ws_client(peer: WebSocketMultiplayerPeer, address: String, port: int) -> Error:
	_configure_ws_peer(peer)
	return peer.create_client(_get_ws_url(address, port))

func _configure_ws_peer(peer: WebSocketMultiplayerPeer) -> void:
	peer.supported_protocols = ws_supported_protocols
	peer.handshake_headers = ws_handshake_headers
	peer.handshake_timeout = ws_handshake_timeout
	peer.inbound_buffer_size = ws_inbound_buffer_size
	peer.outbound_buffer_size = ws_outbound_buffer_size
	peer.max_queued_packets = ws_max_queued_packets

func _get_ws_url(address: String, port: int) -> String:
	if address.begins_with("ws://") or address.begins_with("wss://"):
		return address
	var path := ws_path.strip_edges()
	if path == "":
		path = "/"
	elif not path.begins_with("/"):
		path = "/" + path
	return "%s://%s:%d%s" % ["wss" if ws_secure else "ws", address, port, path]

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
	client_stopped.emit()
	return true

func _on_connected_to_server():
	client_started.emit()

func _on_server_disconnected():
	_address = ""
	_port = 0
	client_stopped.emit()

func _on_connection_failed():
	_address = ""
	_port = 0
	client_failed.emit()
