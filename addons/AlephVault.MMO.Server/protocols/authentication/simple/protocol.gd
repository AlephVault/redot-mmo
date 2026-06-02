extends AlephVault__MMO__Server.Protocols.Authentication.Protocol

func _create_commands_node() -> AlephVault__MMO__Server.Protocols.Commands:
	return AlephVault__MMO__Server.Protocols.Authentication.Simple.Commands.new()

func _create_notifications_node() -> AlephVault__MMO__Server.Protocols.Notifications:
	return AlephVault__MMO__Server.Protocols.Authentication.Simple.Notifications.new()

func handle_list_profiles_requested(connection_id: int) -> void:
	pass

func handle_select_profile_requested(connection_id: int, profile_id: Variant) -> void:
	pass

func handle_close_profile_requested(connection_id: int) -> void:
	pass

func send_profiles_list(connection_id: int, profiles: Array[Variant]) -> bool:
	return notify(connection_id, "profiles_list", [profiles])

func send_profile_invalid(connection_id: int, reason: Variant) -> bool:
	return notify(connection_id, "profile_invalid", [reason])

func send_profile_unavailable(connection_id: int, reason: Variant) -> bool:
	return notify(connection_id, "profile_unavailable", [reason])

func send_profile_selected(connection_id: int, profile: Variant) -> bool:
	return notify(connection_id, "profile_selected", [profile])
