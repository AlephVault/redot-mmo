extends AlephVault__MMO__Client.Protocols.Authentication.Protocol

signal profiles_list(list: Array[Variant])
signal profile_invalid(reason: Variant)
signal profile_unavailable(reason: Variant)
signal profile_selected(profile_id: Variant, profile: Variant)
signal profile_closed(reason: Variant)
signal profile_not_selected(reason: Variant)
signal profile_not_closeable(reason: Variant)

func _create_commands_node() -> AlephVault__MMO__Client.Protocols.Commands:
	return AlephVault__MMO__Client.Protocols.Authentication.Simple.Commands.new()

func _create_notifications_node() -> AlephVault__MMO__Client.Protocols.Notifications:
	return AlephVault__MMO__Client.Protocols.Authentication.Simple.Notifications.new()

func list_profiles() -> bool:
	return command("list_profiles")

func select_profile(profile_id: Variant) -> bool:
	return command("select_profile", [profile_id])

func close_profile() -> bool:
	return command("close_profile")

func handle_profiles_list(list: Array[Variant]) -> void:
	profiles_list.emit(list)

func handle_profile_invalid(reason: Variant) -> void:
	profile_invalid.emit(reason)

func handle_profile_unavailable(reason: Variant) -> void:
	profile_unavailable.emit(reason)

func handle_profile_selected(profile_id: Variant, profile: Variant) -> void:
	profile_selected.emit(profile_id, profile)

func handle_profile_closed(reason: Variant = null) -> void:
	profile_closed.emit(reason)

func handle_profile_not_selected(reason: Variant = null) -> void:
	profile_not_selected.emit(reason)

func handle_profile_not_closeable(reason: Variant = null) -> void:
	profile_not_closeable.emit(reason)
