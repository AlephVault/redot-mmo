extends AlephVault__MMO__Client.Protocols.Commands

@rpc("authority", "call_remote", "reliable")
func login(method: String, payload: Variant = null) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func logout() -> void:
	pass
