extends Node

## Implement this method to define the dependencies
## of the current protocol. Do it in terms of classes
## extending AlephVault__MMO__Client.Protocol.
static func _get_dependencies(): Array[Script]:
	return []

## The protocol classes this protocol depends on.
static var dependencies: Array[Script]:
	get:
		return _get_dependencies()
	set(value):
		assert(false, "The client's protocol dependencies cannot be set this way")

## Hook invoked after the client connects to a server successfully.
async func client_started() -> void:
	pass

## Hook invoked after the client disconnects from the server.
async func client_stopped() -> void:
	pass

## Override this to instantiate the node serving the
## protocol commands issued to the server.
func _create_commands_node() -> AlephVault__MMO__Client.ProtocolCommands:
	return AlephVault__MMO__Client.ProtocolCommands.new()

## Override this to instantiate the node serving the
## protocol notifications received by the client.
func _create_notifications_node() -> AlephVault__MMO__Client.ProtocolNotifications:
	return AlephVault__MMO__Client.ProtocolNotifications.new()

## Installs this protocol under a connection as:
##
## <protocol-name>
##   Commands
##   Notifications
func _install(connection: AlephVault__MMO__Client.Connection) -> void:
	var protocol = Node.new()
	protocol.name = name
	print("[AlephVault.MMO:Client] Adding Protocol to: " + String(connection.get_path()) + ":", protocol)
	connection.add_child(protocol, true)

	var commands = _create_commands_node()
	commands.name = "Commands"
	print("[AlephVault.MMO:Client] Adding Protocol Commands to: " + String(protocol.get_path()) + ":", commands)
	protocol.add_child(commands, true)

	var notifications = _create_notifications_node()
	notifications.name = "Notifications"
	print(
		"[AlephVault.MMO:Client] Adding Protocol Notifications to: "
		+ String(protocol.get_path()) + ":", notifications
	)
	protocol.add_child(notifications, true)
