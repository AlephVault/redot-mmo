extends Node

## Implement this method to define the dependencies
## of the current protocol. Do it in terms of classes
## extending AlephVault__MMO__Server.Protocol.
static func _get_dependencies(): Array[Script]:
	return []

## The protocol classes this protocol depends on.
static var dependencies: Array[Script]:
	get:
		return _get_dependencies()
	set(value):
		assert(false, "The server's protocol dependencies cannot be set this way")

## Override this to instantiate the node serving the
## protocol commands issued to the server.
func _create_commands_node() -> AlephVault__MMO__Server.ProtocolCommands:
	return AlephVault__MMO__Server.ProtocolCommands.new()

## Override this to instantiate the node serving the
## protocol notifications sent to the client.
func _create_notifications_node() -> AlephVault__MMO__Server.ProtocolNotifications:
	return AlephVault__MMO__Server.ProtocolNotifications.new()

## Installs this protocol under a connection as:
##
## <protocol-name>
##   Commands
##   Notifications
func _install(connection: AlephVault__MMO__Server.Connection) -> void:
	var protocol = Node.new()
	protocol.name = name
	print("[AlephVault.MMO:Server] Adding Protocol to: " + String(connection.get_path()) + ":", protocol)
	connection.add_child(protocol, true)

	var commands = _create_commands_node()
	commands.name = "Commands"
	print("[AlephVault.MMO:Server] Adding Protocol Commands to: " + String(protocol.get_path()) + ":", commands)
	protocol.add_child(commands, true)

	var notifications = _create_notifications_node()
	notifications.name = "Notifications"
	print(
		"[AlephVault.MMO:Server] Adding Protocol Notifications to: "
		+ String(protocol.get_path()) + ":", notifications
	)
	protocol.add_child(notifications, true)
