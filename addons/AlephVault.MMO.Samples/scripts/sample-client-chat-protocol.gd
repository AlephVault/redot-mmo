extends AlephVault__MMO__Client.Protocols.Protocol

const Commands = preload("./sample-client-connection-commands.gd")
const Notifications = preload("./sample-client-connection-notifications.gd")

func _create_commands_node() -> AlephVault__MMO__Client.Protocols.Commands:
	return Commands.new()

func _create_notifications_node() -> AlephVault__MMO__Client.Protocols.Notifications:
	return Notifications.new()
