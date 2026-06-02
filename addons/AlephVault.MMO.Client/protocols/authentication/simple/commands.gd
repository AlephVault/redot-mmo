extends AlephVault__MMO__Client.Protocols.Authentication.Commands

@rpc("authority", "call_remote", "reliable")
func list_profiles() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func select_profile(profile_id: Variant) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func close_profile() -> void:
	pass
