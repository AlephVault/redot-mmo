extends AlephVault__MMO__Client.Protocols.Commands


@rpc("authority", "call_remote", "reliable")
func list_connected_users() -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func me() -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func list_users() -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func reset_user_score(username: String) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func set_user_score(username: String, score: int) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func kick_user(username: String) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func stop_match(match_id: int) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func propose_match(username: String) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func cancel_match(match_id: int) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func accept_match(match_id: int) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func decline_match(match_id: int) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func play_match(match_id: int, action: String) -> void:
	pass
