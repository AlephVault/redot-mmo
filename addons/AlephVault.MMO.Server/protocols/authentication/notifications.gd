extends AlephVault__MMO__Server.Protocols.Notifications

@rpc("authority", "call_remote", "reliable")
func login_ok(payload: Variant = null) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func login_failed(payload: Variant = null) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func kicked(payload: Variant = null) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func logged_out() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func not_logged_in() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func account_already_in_use() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func already_logged_in() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func forbidden() -> void:
	pass
