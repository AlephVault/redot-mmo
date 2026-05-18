extends AlephVault__MMO__Client.Protocol

const Commands = preload("./sample-client-connection-commands.gd")
const Notifications = preload("./sample-client-connection-notifications.gd")

func _create_commands_node() -> AlephVault__MMO__Client.ProtocolCommands:
	return Commands.new()

func _create_notifications_node() -> AlephVault__MMO__Client.ProtocolNotifications:
	return Notifications.new()
