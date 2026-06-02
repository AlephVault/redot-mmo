extends AlephVault__MMO__Server.Protocols.Authentication.Notifications

@rpc("authority", "call_remote", "reliable")
func profiles_list(list: Array[Variant]) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func profile_invalid(reason: Variant) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func profile_unavailable(reason: Variant) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func profile_selected(profile: Variant) -> void:
	pass
