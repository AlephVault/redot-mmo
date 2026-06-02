extends AlephVault__MMO__Client.Protocols.Authentication.Protocol

func _create_commands_node() -> AlephVault__MMO__Client.Protocols.Commands:
	return AlephVault__MMO__Client.Protocols.Authentication.Simple.Commands.new()

func _create_notifications_node() -> AlephVault__MMO__Client.Protocols.Notifications:
	return AlephVault__MMO__Client.Protocols.Authentication.Simple.Notifications.new()
