extends AlephVault__MMO__Server.Protocols.Protocol


const AuthProtocol = preload("./rps-auth-server-protocol.gd")
const Commands = preload("./rps-server-commands.gd")
const Notifications = preload("./rps-server-notifications.gd")

const STATUS_PENDING := "pending"
const STATUS_ACCEPTED := "accepted"
const ACTION_PENDING := "pending"
const ACTIONS := ["rock", "paper", "scissors"]

var _matches: Dictionary = {}
var _next_match_id := 1
var _auth_connected := false


static func _get_dependencies() -> Array[Script]:
	return [AuthProtocol]


func _ready() -> void:
	call_deferred("_ensure_auth_connected")


func server_started() -> void:
	_ensure_auth_connected()


func _ensure_auth_connected() -> void:
	if _auth_connected:
		return
	var auth := _auth()
	if auth != null and not auth.session_terminating.is_connected(_on_session_terminating):
		auth.session_terminating.connect(_on_session_terminating)
		_auth_connected = true


func _create_commands_node() -> AlephVault__MMO__Server.Protocols.Commands:
	return Commands.new()


func _create_notifications_node() -> AlephVault__MMO__Server.Protocols.Notifications:
	return Notifications.new()


func _auth() -> AuthProtocol:
	return get_protocol(AuthProtocol) as AuthProtocol


func _notify(connection_id: int, method: String, args: Array = []) -> void:
	notify(connection_id, method, args)


func _profile(connection_id: int) -> Dictionary:
	var auth := _auth()
	if auth == null:
		return {}
	return auth.get_connected_profile(connection_id)


func _username(connection_id: int) -> String:
	var profile := _profile(connection_id)
	return str(profile.get("username", ""))


func _role(connection_id: int) -> String:
	var profile := _profile(connection_id)
	return str(profile.get("role", ""))


func _is_admin(connection_id: int) -> bool:
	return _role(connection_id) == AuthProtocol.ROLE_ADMIN


func _is_player(connection_id: int) -> bool:
	return _role(connection_id) == AuthProtocol.ROLE_PLAYER


func _login_required(connection_id: int, action: Callable, allowed: Callable = Callable()) -> Variant:
	var auth := _auth()
	if auth == null:
		return null
	return auth.login_required(connection_id, action, allowed)


func handle_list_connected_users(connection_id: int) -> void:
	var action := func(id: int):
		_notify(id, "connected_users_list", [_auth().get_connected_profiles()])
	var allowed := func(id: int): return _is_admin(id) or _is_player(id)
	_login_required(connection_id, action, allowed)


func handle_me(connection_id: int) -> void:
	var action := func(id: int):
		_notify(id, "you", [_profile(id)])
	var allowed := func(id: int): return _is_admin(id) or _is_player(id)
	_login_required(connection_id, action, allowed)


func handle_list_users(connection_id: int) -> void:
	var action := func(id: int):
		_notify(id, "users_list", [_auth().list_profiles()])
	_login_required(connection_id, action, Callable(self, "_is_admin"))


func handle_reset_user_score(connection_id: int, username: String) -> void:
	var action := func(id: int):
		if not _auth().set_score(username, 0):
			_notify(id, "user_not_found", [username])
			return
		_notify(id, "score_reset", [username])
	_login_required(connection_id, action, Callable(self, "_is_admin"))


func handle_set_user_score(connection_id: int, username: String, score: int) -> void:
	var action := func(id: int):
		if not _auth().set_score(username, score):
			_notify(id, "user_not_found", [username])
			return
		_notify(id, "score_set", [username, score])
	_login_required(connection_id, action, Callable(self, "_is_admin"))


func handle_kick_user(connection_id: int, username: String) -> void:
	var action := func(id: int):
		var profile := _auth().get_profile(username)
		if profile.is_empty():
			_notify(id, "user_not_found", [username])
			return
		_notify(id, "kicked", [str(profile["username"])])
		_auth().kick(str(profile["username"]).to_lower(), {"reason": "admin_kick", "admin": _username(id)})
	_login_required(connection_id, action, Callable(self, "_is_admin"))


func handle_admin_stop_match(connection_id: int, match_id: int) -> void:
	var action := func(id: int):
		if not _matches.has(match_id):
			_notify(id, "match_not_found", [match_id])
			return
		_stop_match(match_id, _username(id))
		_notify(id, "match_stopped", [match_id, _username(id)])
	_login_required(connection_id, action, Callable(self, "_is_admin"))


func handle_propose_match(connection_id: int, username: String) -> void:
	var action := func(id: int):
		var auth := _auth()
		var from_name := _username(id)
		var target := auth.get_profile(username)
		if target.is_empty() or str(target["role"]) != AuthProtocol.ROLE_PLAYER:
			_notify(id, "user_not_found", [username])
			return
		var to_name := str(target["username"])
		var to_connection_id := auth.get_connected_connection_id(to_name)
		if to_connection_id == 0 or to_name.to_lower() == from_name.to_lower():
			_notify(id, "user_not_found", [username])
			return
		var existing_id := _find_match_between(from_name, to_name)
		if existing_id != 0:
			_notify(id, "match_proposal_already_exists", [existing_id, to_name, true])
			_notify(to_connection_id, "match_proposal_already_exists", [existing_id, from_name, false])
			return
		var match_id := _next_match_id
		_next_match_id += 1
		_matches[match_id] = {
			"from": from_name,
			"to": to_name,
			"status": STATUS_PENDING,
			"play_from": ACTION_PENDING,
			"play_to": ACTION_PENDING,
		}
		_notify(id, "match_proposed", [match_id, to_name, true])
		_notify(to_connection_id, "match_proposed", [match_id, from_name, false])
	_login_required(connection_id, action, Callable(self, "_is_player"))


func handle_cancel_match(connection_id: int, match_id: int) -> void:
	var action := func(id: int):
		if not _matches.has(match_id):
			_notify(id, "match_not_found", [match_id])
			return
		var match: Dictionary = _matches[match_id]
		if str(match["from"]).to_lower() != _username(id).to_lower() or match["status"] != STATUS_PENDING:
			_notify(id, "match_not_found", [match_id])
			return
		var other_id := _auth().get_connected_connection_id(str(match["to"]))
		_matches.erase(match_id)
		_notify(id, "match_proposal_canceled", [match_id, true])
		if other_id != 0:
			_notify(other_id, "match_proposal_canceled", [match_id, false])
	_login_required(connection_id, action, Callable(self, "_is_player"))


func handle_accept_match(connection_id: int, match_id: int) -> void:
	var action := func(id: int):
		if not _matches.has(match_id):
			_notify(id, "match_not_found", [match_id])
			return
		var match_: Dictionary = _matches[match_id]
		if str(match_["to"]).to_lower() != _username(id).to_lower() or match_["status"] != STATUS_PENDING:
			_notify(id, "match_not_found", [match_id])
			return
		match_["status"] = STATUS_ACCEPTED
		var other_id := _auth().get_connected_connection_id(str(match_["from"]))
		_notify(id, "match_proposal_accepted", [match_id, true])
		if other_id != 0:
			_notify(other_id, "match_proposal_accepted", [match_id, false])
	_login_required(connection_id, action, Callable(self, "_is_player"))


func handle_decline_match(connection_id: int, match_id: int) -> void:
	var action := func(id: int):
		if not _matches.has(match_id):
			_notify(id, "match_not_found", [match_id])
			return
		var match: Dictionary = _matches[match_id]
		if str(match["to"]).to_lower() != _username(id).to_lower() or match["status"] != STATUS_PENDING:
			_notify(id, "match_not_found", [match_id])
			return
		var other_id := _auth().get_connected_connection_id(str(match["from"]))
		_matches.erase(match_id)
		_notify(id, "match_proposal_declined", [match_id, true])
		if other_id != 0:
			_notify(other_id, "match_proposal_declined", [match_id, false])
	_login_required(connection_id, action, Callable(self, "_is_player"))


func handle_play_match(connection_id: int, match_id: int, action: String) -> void:
	var play_action := func(id: int):
		action = action.strip_edges().to_lower()
		if not _matches.has(match_id) or not ACTIONS.has(action):
			_notify(id, "match_not_found", [match_id])
			return
		var match_: Dictionary = _matches[match_id]
		var username := _username(id)
		var play_key := ""
		var opponent_name := ""
		if str(match_["from"]).to_lower() == username.to_lower():
			play_key = "play_from"
			opponent_name = str(match_["to"])
		elif str(match_["to"]).to_lower() == username.to_lower():
			play_key = "play_to"
			opponent_name = str(match_["from"])
		else:
			_notify(id, "match_not_found", [match_id])
			return
		if match_["status"] != STATUS_ACCEPTED:
			_notify(id, "match_not_found", [match_id])
			return
		if match_[play_key] != ACTION_PENDING:
			_notify(id, "already_played", [match_id])
			return
		match_[play_key] = action
		var opponent_id := _auth().get_connected_connection_id(opponent_name)
		_notify(id, "match_play", [match_id, true, action])
		if opponent_id != 0:
			_notify(opponent_id, "match_play", [match_id, false, ""])
		if match_["play_from"] != ACTION_PENDING and match_["play_to"] != ACTION_PENDING:
			_finish_match(match_id)
	_login_required(connection_id, play_action, Callable(self, "_is_player"))


func _finish_match(match_id: int) -> void:
	var match: Dictionary = _matches[match_id]
	var from_action := str(match["play_from"])
	var to_action := str(match["play_to"])
	var from_result := _result(from_action, to_action)
	var to_result := _result(to_action, from_action)
	if from_result == "win":
		_auth().add_score(str(match["from"]), 1)
	elif to_result == "win":
		_auth().add_score(str(match["to"]), 1)
	var from_id := _auth().get_connected_connection_id(str(match["from"]))
	var to_id := _auth().get_connected_connection_id(str(match["to"]))
	_matches.erase(match_id)
	if from_id != 0:
		_notify(from_id, "match_ended", [match_id, to_action, from_result])
	if to_id != 0:
		_notify(to_id, "match_ended", [match_id, from_action, to_result])


func _result(action: String, opponent_action: String) -> String:
	if action == opponent_action:
		return "tie"
	if (
		(action == "rock" and opponent_action == "scissors")
		or (action == "paper" and opponent_action == "rock")
		or (action == "scissors" and opponent_action == "paper")
	):
		return "win"
	return "lose"


func _find_match_between(a: String, b: String) -> int:
	var left := a.to_lower()
	var right := b.to_lower()
	for match_id in _matches.keys():
		var match: Dictionary = _matches[match_id]
		var from_name := str(match["from"]).to_lower()
		var to_name := str(match["to"]).to_lower()
		if (from_name == left and to_name == right) or (from_name == right and to_name == left):
			return int(match_id)
	return 0


func _stop_match(match_id: int, actor: String) -> void:
	var match: Dictionary = _matches[match_id]
	_matches.erase(match_id)
	for username in [str(match["from"]), str(match["to"])]:
		var connection_id := _auth().get_connected_connection_id(username)
		if connection_id != 0:
			_notify(connection_id, "match_stopped", [match_id, actor])


func _on_session_terminating(connection_id: int, reason: Variant) -> void:
	var username := str(_auth().get_session_account_id(connection_id))
	if username == "":
		return
	var match_ids: Array = []
	match_ids.assign(_matches.keys())
	for match_id in match_ids:
		if not _matches.has(match_id):
			continue
		var match: Dictionary = _matches[match_id]
		var is_from := str(match["from"]).to_lower() == username.to_lower()
		var is_to := str(match["to"]).to_lower() == username.to_lower()
		if not is_from and not is_to:
			continue
		if match["status"] == STATUS_PENDING:
			_matches.erase(match_id)
			var other_name := str(match["to"] if is_from else match["from"])
			var other_id := _auth().get_connected_connection_id(other_name)
			if other_id != 0:
				if is_from:
					_notify(other_id, "match_proposal_canceled", [match_id, false])
				else:
					_notify(other_id, "match_proposal_declined", [match_id, false])
		else:
			_stop_match(match_id, username)
