extends AlephVault__MMO__Server.Protocols.Commands


func _rps_protocol():
	return protocol_node()


func _connection_id() -> int:
	var connection = connection_node()
	return connection.id if connection != null else 0


@rpc("authority", "call_remote", "reliable")
func list_connected_users() -> void:
	_rps_protocol().handle_list_connected_users(_connection_id())


@rpc("authority", "call_remote", "reliable")
func me() -> void:
	_rps_protocol().handle_me(_connection_id())


@rpc("authority", "call_remote", "reliable")
func list_users() -> void:
	_rps_protocol().handle_list_users(_connection_id())


@rpc("authority", "call_remote", "reliable")
func reset_user_score(username: String) -> void:
	_rps_protocol().handle_reset_user_score(_connection_id(), username)


@rpc("authority", "call_remote", "reliable")
func set_user_score(username: String, score: int) -> void:
	_rps_protocol().handle_set_user_score(_connection_id(), username, score)


@rpc("authority", "call_remote", "reliable")
func kick_user(username: String) -> void:
	_rps_protocol().handle_kick_user(_connection_id(), username)


@rpc("authority", "call_remote", "reliable")
func stop_match(match_id: int) -> void:
	_rps_protocol().handle_admin_stop_match(_connection_id(), match_id)


@rpc("authority", "call_remote", "reliable")
func propose_match(username: String) -> void:
	print("Proposing to:", username)
	_rps_protocol().handle_propose_match(_connection_id(), username)


@rpc("authority", "call_remote", "reliable")
func cancel_match(match_id: int) -> void:
	_rps_protocol().handle_cancel_match(_connection_id(), match_id)


@rpc("authority", "call_remote", "reliable")
func accept_match(match_id: int) -> void:
	_rps_protocol().handle_accept_match(_connection_id(), match_id)


@rpc("authority", "call_remote", "reliable")
func decline_match(match_id: int) -> void:
	_rps_protocol().handle_decline_match(_connection_id(), match_id)


@rpc("authority", "call_remote", "reliable")
func play_match(match_id: int, action: String) -> void:
	_rps_protocol().handle_play_match(_connection_id(), match_id, action)
