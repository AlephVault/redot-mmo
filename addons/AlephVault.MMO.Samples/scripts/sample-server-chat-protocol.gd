extends AlephVault__MMO__Server.Protocol

const Commands = preload("./sample-server-connection-commands.gd")
const Notifications = preload("./sample-server-connection-notifications.gd")

func _create_commands_node() -> AlephVault__MMO__Server.ProtocolCommands:
	return Commands.new()

func _create_notifications_node() -> AlephVault__MMO__Server.ProtocolNotifications:
	return Notifications.new()
