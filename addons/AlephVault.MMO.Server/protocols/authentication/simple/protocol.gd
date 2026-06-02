extends AlephVault__MMO__Server.Protocols.Authentication.Protocol

func _create_commands_node() -> AlephVault__MMO__Server.Protocols.Commands:
	return AlephVault__MMO__Server.Protocols.Authentication.Simple.Commands.new()

func _create_notifications_node() -> AlephVault__MMO__Server.Protocols.Notifications:
	return AlephVault__MMO__Server.Protocols.Authentication.Simple.Notifications.new()
