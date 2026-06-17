extends Node
## This is a base MMO Server node. Everything will occur
## right below this class related to MMO games.

func _ready() -> void:
	# First, take all the nodes that are Protocol instances.
	var protocol_nodes := _take_protocol_nodes()

	# Also, set a place for the protocols.
	var manager = AlephVault__MMO__Server.Protocols.Manager.new()
	manager.name = "Protocols"
	print("[AlephVault.MMO:Server] Adding Protocols to: " + String(get_path()) + ":", manager)
	add_child(manager, true)
	_protocols = manager

	# Add all Protocol nodes before Connections can react to connection signals.
	_add_sorted_protocol_nodes(protocol_nodes)

	# Also, set a place for the child connections.
	var connections = AlephVault__MMO__Server.Connections.new()
	connections.name = "Connections"
	print("[AlephVault.MMO:Server] Adding Connections to: " + String(get_path()) + ":", connections)
	add_child(connections, true)
	_connections = connections

	_connect_protocol_hooks()

	request_ready()

func _exit_tree() -> void:
	stop()
	
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

## The type of peer to create when launching the server.
@export var peer_type: AlephVault__MMO__Common.Setup.PeerType = AlephVault__MMO__Common.Setup.PeerType.ENET

## ENet bind address to use when launching the server.
@export var enet_bind_address: String = "*"

## ENet maximum client count.
@export var enet_max_clients: int = 4095

## ENet maximum channel count.
@export var enet_max_channels: int = 0

## ENet inbound bandwidth limit.
@export var enet_in_bandwidth: int = 0

## ENet outbound bandwidth limit.
@export var enet_out_bandwidth: int = 0

## WebSocket bind address.
@export var ws_bind_address: String = "*"

## WebSocket protocols to accept during the handshake.
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

## WebSocket TLS certificate resource path.
@export_file var ws_certificate_path: String = ""

## WebSocket TLS private key resource path.
@export_file var ws_key_path: String = ""

# The current address from the current launch.
var _address: String

# The current port from the current launch.
var _port: int

# The parent of the protocols.
var _protocols: AlephVault__MMO__Server.Protocols.Manager

## The parent of the protocols.
var protocols: AlephVault__MMO__Server.Protocols.Manager:
	get:
		return _protocols
	set(value):
		assert(false, "The server's protocols cannot be set this way")

# The parent of the connections.
var _connections: AlephVault__MMO__Server.Connections

## The parent of the connections.
var connections: AlephVault__MMO__Server.Connections:
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
		protocol_classes, AlephVault__MMO__Server.Protocols.Protocol
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
			var server_started_hook := Callable(child, "server_started")
			if not server_started.is_connected(server_started_hook):
				server_started.connect(server_started_hook)
			var server_stopped_hook := Callable(child, "server_stopped")
			if not server_stopped.is_connected(server_stopped_hook):
				server_stopped.connect(server_stopped_hook)

func _disconnect_protocol_hooks() -> void:
	for child in _protocols.get_children():
		if _node_extends_protocol(child):
			var server_started_hook := Callable(child, "server_started")
			if server_started.is_connected(server_started_hook):
				server_started.disconnect(server_started_hook)
			var server_stopped_hook := Callable(child, "server_stopped")
			if server_stopped.is_connected(server_stopped_hook):
				server_stopped.disconnect(server_stopped_hook)

func _protocols_client_entered(id: int) -> void:
	for child in _protocols.get_children():
		if _node_extends_protocol(child):
			child.client_entered(id)

func _protocols_client_left(id: int) -> void:
	for child in _protocols.get_children():
		if _node_extends_protocol(child):
			child.client_left(id)

func _node_extends_protocol(node: Node) -> bool:
	var script = node.get_script() as Script
	while script != null:
		if script == AlephVault__MMO__Server.Protocols.Protocol:
			return true
		script = script.get_base_script()
	return false

## Launches a server.
##
## ENet-specific parameters override the exported enet_* properties when they
## are not -1. WebSocket parameters are read from exported ws_* properties.
func launch(
	port: int, max_clients: int = -1, max_channels: int = -1,
	in_bandwidth: int = -1, out_bandwidth: int = -1
) -> Error:
	"""
	Launches a server.
	
	ENet-specific parameters override the exported enet_* properties when they
	are not -1. WebSocket parameters are read from exported ws_* properties.
	"""
	
	var peer: MultiplayerPeer
	var err: Error
	match peer_type:
		AlephVault__MMO__Common.Setup.PeerType.ENET:
			peer = ENetMultiplayerPeer.new()
			err = _create_enet_server(peer, port, max_clients, max_channels, in_bandwidth, out_bandwidth)
		AlephVault__MMO__Common.Setup.PeerType.WEBSOCKETS:
			peer = WebSocketMultiplayerPeer.new()
			err = _create_ws_server(peer, port)
		_:
			return ERR_INVALID_PARAMETER
	if err != OK:
		return err
	_address = enet_bind_address if peer_type == AlephVault__MMO__Common.Setup.PeerType.ENET else ws_bind_address
	_port = port
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	server_started.emit()
	return OK

func _create_enet_server(
	peer: ENetMultiplayerPeer, port: int, max_clients: int, max_channels: int,
	in_bandwidth: int, out_bandwidth: int
) -> Error:
	peer.set_bind_ip(enet_bind_address)
	return peer.create_server(
		port,
		enet_max_clients if max_clients == -1 else max_clients,
		enet_max_channels if max_channels == -1 else max_channels,
		enet_in_bandwidth if in_bandwidth == -1 else in_bandwidth,
		enet_out_bandwidth if out_bandwidth == -1 else out_bandwidth
	)

func _create_ws_server(peer: WebSocketMultiplayerPeer, port: int) -> Error:
	_configure_ws_peer(peer)
	var tls_options: TLSOptions
	if ws_certificate_path != "" or ws_key_path != "":
		if ws_certificate_path == "" or ws_key_path == "":
			return ERR_INVALID_PARAMETER
		var certificate := X509Certificate.new()
		var err := certificate.load(ws_certificate_path)
		if err != OK:
			return err
		var key := CryptoKey.new()
		err = key.load(ws_key_path)
		if err != OK:
			return err
		tls_options = TLSOptions.server(key, certificate)
	return peer.create_server(port, ws_bind_address, tls_options)

func _configure_ws_peer(peer: WebSocketMultiplayerPeer) -> void:
	peer.supported_protocols = ws_supported_protocols
	peer.handshake_headers = ws_handshake_headers
	peer.handshake_timeout = ws_handshake_timeout
	peer.inbound_buffer_size = ws_inbound_buffer_size
	peer.outbound_buffer_size = ws_outbound_buffer_size
	peer.max_queued_packets = ws_max_queued_packets

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

func _on_peer_connected(id: int):
	if id != 1:
		client_entered.emit(id)
		_protocols_client_entered(id)

func _on_peer_disconnected(id: int):
	if id != 1:
		_protocols_client_left(id)
		client_left.emit(id)
