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
func profile_selected(profile_id: Variant, profile: Variant) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func profile_closed(reason: Variant = null) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func profile_not_selected(reason: Variant = null) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func profile_not_closeable(reason: Variant = null) -> void:
	pass
