extends AlephVault__MMO__Server.Protocols.Notifications


@rpc("authority", "call_remote", "reliable")
func connected_users_list(list: Array[Dictionary]) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func you(profile: Dictionary) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func users_list(list: Array[Dictionary]) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func score_reset(username: String) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func score_set(username: String, score: int) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func kicked(username: String) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func match_stopped(match_id: int, actor: String = "") -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func user_not_found(username: String) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func match_not_found(match_id: int) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func match_proposed(match_id: int, username: String, by_you: bool) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func match_proposal_already_exists(match_id: int, username: String, by_you: bool) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func match_proposal_canceled(match_id: int, by_you: bool) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func match_proposal_declined(match_id: int, by_you: bool) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func match_proposal_accepted(match_id: int, by_you: bool) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func match_play(match_id: int, by_you: bool, action: String) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func already_played(match_id: int) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func match_ended(match_id: int, opponent_action: String, result: String) -> void:
	pass
