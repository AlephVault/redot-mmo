extends AlephVault__MMO__Client.Protocols.Notifications


func _ui():
	var main = $"../../../.."
	return main.client_ui if main != null else null


func _message(method: String, args: Array = []) -> void:
	var ui = _ui()
	if ui != null and ui.has_method(method):
		ui.callv(method, args)


@rpc("authority", "call_remote", "reliable")
func connected_users_list(list: Array[Dictionary]) -> void:
	_message("message_connected_users_list", [list])


@rpc("authority", "call_remote", "reliable")
func you(profile: Dictionary) -> void:
	_message("message_you", [profile])


@rpc("authority", "call_remote", "reliable")
func users_list(list: Array[Dictionary]) -> void:
	_message("message_users_list", [list])


@rpc("authority", "call_remote", "reliable")
func score_reset(username: String) -> void:
	_message("message_score_reset", [username])


@rpc("authority", "call_remote", "reliable")
func score_set(username: String, score: int) -> void:
	_message("message_score_set", [username, score])


@rpc("authority", "call_remote", "reliable")
func kicked(username: String) -> void:
	_message("message_kicked", [username])


@rpc("authority", "call_remote", "reliable")
func match_stopped(match_id: int, actor: String = "") -> void:
	_message("message_match_stopped", [match_id, actor])


@rpc("authority", "call_remote", "reliable")
func user_not_found(username: String) -> void:
	_message("message_user_not_found", [username])


@rpc("authority", "call_remote", "reliable")
func match_not_found(match_id: int) -> void:
	_message("message_match_not_found", [match_id])


@rpc("authority", "call_remote", "reliable")
func match_proposed(match_id: int, username: String, by_you: bool) -> void:
	_message("message_match_proposed", [match_id, username, by_you])


@rpc("authority", "call_remote", "reliable")
func match_proposal_already_exists(match_id: int, username: String, by_you: bool) -> void:
	_message("message_match_proposal_already_exists", [match_id, username, by_you])


@rpc("authority", "call_remote", "reliable")
func match_proposal_canceled(match_id: int, by_you: bool) -> void:
	_message("message_match_proposal_canceled", [match_id, by_you])


@rpc("authority", "call_remote", "reliable")
func match_proposal_declined(match_id: int, by_you: bool) -> void:
	_message("message_match_proposal_declined", [match_id, by_you])


@rpc("authority", "call_remote", "reliable")
func match_proposal_accepted(match_id: int, by_you: bool) -> void:
	_message("message_match_proposal_accepted", [match_id, by_you])


@rpc("authority", "call_remote", "reliable")
func match_play(match_id: int, by_you: bool, action: String) -> void:
	_message("message_match_play", [match_id, by_you, action])


@rpc("authority", "call_remote", "reliable")
func already_played(match_id: int) -> void:
	_message("message_already_played", [match_id])


@rpc("authority", "call_remote", "reliable")
func match_ended(match_id: int, opponent_action: String, result: String) -> void:
	_message("message_match_ended", [match_id, opponent_action, result])
