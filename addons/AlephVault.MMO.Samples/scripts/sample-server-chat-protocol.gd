extends AlephVault__MMO__Server.Protocols.Protocol

const Commands = preload("./sample-server-connection-commands.gd")
const Notifications = preload("./sample-server-connection-notifications.gd")

func _create_commands_node() -> AlephVault__MMO__Server.Protocols.Commands:
	return Commands.new()

func _create_notifications_node() -> AlephVault__MMO__Server.Protocols.Notifications:
	return Notifications.new()
