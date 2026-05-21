extends Node

## Implement this method to define the dependencies
## of the current protocol. Do it in terms of classes
## extending AlephVault__MMO__Server.Protocols.Protocol.
static func _get_dependencies() -> Array[Script]:
	return []

## The protocol classes this protocol depends on.
static var dependencies: Array[Script]:
	get:
		return _get_dependencies()
	set(value):
		assert(false, "The server's protocol dependencies cannot be set this way")

## Hook invoked after the server is launched successfully.
func server_started() -> void:
	pass

## Hook invoked after the server is stopped successfully.
func server_stopped() -> void:
	pass

## Hook invoked after a client connection is established.
func client_entered(id: int) -> void:
	pass

## Hook invoked before a client connection is removed.
func client_left(id: int) -> void:
	pass

## Gets another protocol installed under the same Protocols node.
##
## This delegates the lookup to the parent Protocols node. protocol_class must
## be the script used by the target protocol node. Returns null if this protocol
## is not installed under a Protocols node, or if no matching protocol exists.
func get_protocol(protocol_class: Script) -> AlephVault__MMO__Server.Protocols.Protocol:
	var manager = get_parent() as AlephVault__MMO__Server.Protocols.Manager
	if manager == null:
		return null
	return manager.get_protocol(protocol_class)

## Gets the server connection by id.
func get_connection(id: int) -> AlephVault__MMO__Server.Connection:
	var manager = get_parent() as AlephVault__MMO__Server.Protocols.Manager
	if manager == null:
		return null
	var main = manager.get_parent() as AlephVault__MMO__Server.Main
	if main == null or main.connections == null or not main.connections.has_connection(id):
		return null
	return main.connections.get_connection_node(id)

## Gets the notifications node for this protocol in a connection.
##
## The returned node is the Notifications child installed below this protocol's
## per-connection node for the given connection id. Returns null when the
## connection does not exist, this protocol is not installed under a Protocols
## node, or the Notifications node does not exist for that connection.
func get_notifications(id: int) -> AlephVault__MMO__Server.Protocols.Notifications:
	var connection = get_connection(id)
	if connection == null:
		return null
	var protocol = connection.get_node_or_null(str(name))
	if protocol == null:
		return null
	return protocol.get_node_or_null("Notifications") as AlephVault__MMO__Server.Protocols.Notifications

## Sends a notification RPC to a client through this protocol's Notifications node.
##
## method is the RPC method name to invoke on the client-side Notifications
## node. payload contains the method arguments in order.
##
## Returns true when the Notifications node exists and the RPC was attempted.
## Returns false when the connection or Notifications node cannot be found.
func notify(connection_id: int, method: String, payload: Array = []) -> bool:
	notifications := get_notifications(connection_id)
	if notifications == null:
		return false
	notifications.rpc_id.callv([connection_id, method] + payload)
	return true

## Override this to instantiate the node serving the
## protocol commands issued to the server.
func _create_commands_node() -> AlephVault__MMO__Server.Protocols.Commands:
	return AlephVault__MMO__Server.Protocols.Commands.new()

## Override this to instantiate the node serving the
## protocol notifications sent to the client.
func _create_notifications_node() -> AlephVault__MMO__Server.Protocols.Notifications:
	return AlephVault__MMO__Server.Protocols.Notifications.new()

## Installs this protocol under a connection as:
##
## <protocol-name>
##   Commands
##   Notifications
func install(connection: AlephVault__MMO__Server.Connection) -> void:
	var protocol = Node.new()
	protocol.name = name
	print("[AlephVault.MMO:Server] Adding Protocol to: " + String(connection.get_path()) + "/", protocol)
	connection.add_child(protocol, true)

	var commands = _create_commands_node()
	commands.name = "Commands"
	print("[AlephVault.MMO:Server] Adding Protocol Commands to: " + String(protocol.get_path()) + "/", commands)
	protocol.add_child(commands, true)

	var notifications = _create_notifications_node()
	notifications.name = "Notifications"
	print(
		"[AlephVault.MMO:Server] Adding Protocol Notifications to: "
		+ String(protocol.get_path()) + "/", notifications
	)
	protocol.add_child(notifications, true)
