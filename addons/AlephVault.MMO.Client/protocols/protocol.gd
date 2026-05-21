extends Node

## Implement this method to define the dependencies
## of the current protocol. Do it in terms of classes
## extending AlephVault__MMO__Client.Protocols.Protocol.
static func _get_dependencies() -> Array[Script]:
	return []

## The protocol classes this protocol depends on.
static var dependencies: Array[Script]:
	get:
		return _get_dependencies()
	set(value):
		assert(false, "The client's protocol dependencies cannot be set this way")

## Hook invoked after the client connects to a server successfully.
func client_started() -> void:
	pass

## Hook invoked after the client disconnects from the server.
func client_stopped() -> void:
	pass

## Gets another protocol installed under the same Protocols node.
##
## This delegates the lookup to the parent Protocols node. protocol_class must
## be the script used by the target protocol node. Returns null if this protocol
## is not installed under a Protocols node, or if no matching protocol exists.
func get_protocol(protocol_class: Script) -> AlephVault__MMO__Client.Protocols.Protocol:
	var manager = get_parent() as AlephVault__MMO__Client.Protocols.Manager
	if manager == null:
		return null
	return manager.get_protocol(protocol_class)

## Gets the current client connection.
func get_connection() -> AlephVault__MMO__Client.Connection:
	var manager = get_parent() as AlephVault__MMO__Client.Protocols.Manager
	if manager == null:
		return null
	var main = manager.get_parent() as AlephVault__MMO__Client.Main
	if main == null or main.connections == null or main.connections.get_child_count() == 0:
		return null
	return main.connections.get_connection_node()

## Gets the commands node for this protocol in the current connection.
##
## The returned node is the Commands child installed below this protocol's
## per-connection node. Returns null when the client is not connected yet, this
## protocol is not installed under a Protocols node, or the Commands node does
## not exist for the current connection.
func get_commands() -> AlephVault__MMO__Client.Protocols.Commands:
	var connection = get_connection()
	if connection == null:
		return null
	var protocol = connection.get_node_or_null(str(name))
	if protocol == null:
		return null
	return protocol.get_node_or_null("Commands") as AlephVault__MMO__Client.Protocols.Commands

## Sends a command RPC to a client through this protocol's Commands node.
##
## The method is the RPC method name to invoke on the client-side Commands
## node. The arguments contains the method arguments in order.
##
## Returns true when the Commands node exists and the RPC was attempted.
## Returns false when the connection or Commands node cannot be found.
func command(method: String, arguments: Array = []) -> bool:
	commands := get_commands()
	if commands == null:
		return false
	commands.command(method, arguments)
	return true

## Override this to instantiate the node serving the
## protocol commands issued to the server.
func _create_commands_node() -> AlephVault__MMO__Client.Protocols.Commands:
	return AlephVault__MMO__Client.Protocols.Commands.new()

## Override this to instantiate the node serving the
## protocol notifications received by the client.
func _create_notifications_node() -> AlephVault__MMO__Client.Protocols.Notifications:
	return AlephVault__MMO__Client.Protocols.Notifications.new()

## Installs this protocol under a connection as:
##
## <protocol-name>
##   Commands
##   Notifications
func install(connection: AlephVault__MMO__Client.Connection) -> void:
	var protocol = Node.new()
	protocol.name = name
	print("[AlephVault.MMO:Client] Adding Protocol to: " + String(connection.get_path()) + "/", protocol)
	connection.add_child(protocol, true)

	var commands = _create_commands_node()
	commands.name = "Commands"
	print("[AlephVault.MMO:Client] Adding Protocol Commands to: " + String(protocol.get_path()) + "/", commands)
	protocol.add_child(commands, true)

	var notifications = _create_notifications_node()
	notifications.name = "Notifications"
	print(
		"[AlephVault.MMO:Client] Adding Protocol Notifications to: "
		+ String(protocol.get_path()) + "/", notifications
	)
	protocol.add_child(notifications, true)
