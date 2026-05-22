extends Control


const AuthProtocol = preload("./rps-auth-client-protocol.gd")
const RPSProtocol = preload("./rps-client-protocol.gd")

var _logs: TextEdit
var _profile: Label
var _connected_list: ItemList
var _users_list: ItemList
var _address: LineEdit
var _port: SpinBox
var _username: LineEdit
var _password: LineEdit
var _player_target: LineEdit
var _player_match_id: SpinBox
var _player_action: OptionButton
var _admin_username: LineEdit
var _admin_score: SpinBox
var _admin_match_id: SpinBox


func _ready() -> void:
	_build_ui()
	_connect_auth_signals()


func _auth() -> AuthProtocol:
	var main = get_parent() as AlephVault__MMO__Client.Main
	if main == null or main.protocols == null:
		return null
	return main.protocols.get_node_or_null("Auth") as AuthProtocol


func _rps() -> RPSProtocol:
	var main = get_parent() as AlephVault__MMO__Client.Main
	if main == null or main.protocols == null:
		return null
	return main.protocols.get_node_or_null("RPS") as RPSProtocol


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var connection := HBoxContainer.new()
	root.add_child(connection)

	_address = LineEdit.new()
	_address.placeholder_text = "Server"
	_address.text = "127.0.0.1"
	_address.custom_minimum_size.x = 120
	connection.add_child(_address)

	_port = SpinBox.new()
	_port.min_value = 1
	_port.max_value = 65535
	_port.value = 6777
	connection.add_child(_port)

	var connect := Button.new()
	connect.text = "Connect"
	connect.pressed.connect(_connect_to_server)
	connection.add_child(connect)

	var disconnect := Button.new()
	disconnect.text = "Disconnect"
	disconnect.pressed.connect(_disconnect_from_server)
	connection.add_child(disconnect)

	_username = LineEdit.new()
	_username.placeholder_text = "Username"
	_username.custom_minimum_size.x = 120
	connection.add_child(_username)

	_password = LineEdit.new()
	_password.placeholder_text = "Password"
	_password.secret = true
	_password.custom_minimum_size.x = 120
	connection.add_child(_password)

	var login := Button.new()
	login.text = "Log In"
	login.pressed.connect(_login)
	connection.add_child(login)

	var logout := Button.new()
	logout.text = "Log Out"
	logout.pressed.connect(_logout)
	connection.add_child(logout)

	var me := Button.new()
	me.text = "Me"
	me.pressed.connect(_me)
	connection.add_child(me)

	_profile = Label.new()
	_profile.text = "Profile: not logged in"
	root.add_child(_profile)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	_logs = TextEdit.new()
	_logs.editable = false
	_logs.wrap_mode = 1
	_logs.custom_minimum_size.x = 360
	body.add_child(_logs)

	var tabs := TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)

	tabs.add_child(_build_player_tab())
	tabs.add_child(_build_admin_tab())


func _build_player_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "User Actions"
	tab.add_theme_constant_override("separation", 8)

	var list_bar := HBoxContainer.new()
	tab.add_child(list_bar)
	var refresh := Button.new()
	refresh.text = "Refresh Active Users"
	refresh.pressed.connect(_refresh_connected_users)
	list_bar.add_child(refresh)

	_connected_list = ItemList.new()
	_connected_list.custom_minimum_size.y = 170
	_connected_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(_connected_list)

	var propose_bar := HBoxContainer.new()
	tab.add_child(propose_bar)
	_player_target = LineEdit.new()
	_player_target.placeholder_text = "Opponent username"
	_player_target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	propose_bar.add_child(_player_target)
	var propose := Button.new()
	propose.text = "Propose"
	propose.pressed.connect(_propose_match)
	propose_bar.add_child(propose)

	var match_bar := HBoxContainer.new()
	tab.add_child(match_bar)
	_player_match_id = _match_spinbox()
	match_bar.add_child(_player_match_id)
	for item in [
		["Cancel", _cancel_match],
		["Accept", _accept_match],
		["Decline", _decline_match],
	]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(item[1])
		match_bar.add_child(button)

	var play_bar := HBoxContainer.new()
	tab.add_child(play_bar)
	_player_action = OptionButton.new()
	for action in ["rock", "paper", "scissors"]:
		_player_action.add_item(action)
	play_bar.add_child(_player_action)
	var play := Button.new()
	play.text = "Play"
	play.pressed.connect(_play_match)
	play_bar.add_child(play)

	return tab


func _build_admin_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "Admin Actions"
	tab.add_theme_constant_override("separation", 8)

	var refresh_bar := HBoxContainer.new()
	tab.add_child(refresh_bar)
	var refresh_connected := Button.new()
	refresh_connected.text = "Refresh Active Users"
	refresh_connected.pressed.connect(_refresh_connected_users)
	refresh_bar.add_child(refresh_connected)
	var refresh_users := Button.new()
	refresh_users.text = "Refresh All Users"
	refresh_users.pressed.connect(_refresh_users)
	refresh_bar.add_child(refresh_users)

	_users_list = ItemList.new()
	_users_list.custom_minimum_size.y = 170
	_users_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(_users_list)

	var user_bar := HBoxContainer.new()
	tab.add_child(user_bar)
	_admin_username = LineEdit.new()
	_admin_username.placeholder_text = "Username"
	_admin_username.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	user_bar.add_child(_admin_username)
	_admin_score = SpinBox.new()
	_admin_score.min_value = 0
	_admin_score.max_value = 999999
	user_bar.add_child(_admin_score)

	for item in [
		["Reset Score", _reset_score],
		["Set Score", _set_score],
		["Kick", _kick_user],
	]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(item[1])
		user_bar.add_child(button)

	var match_bar := HBoxContainer.new()
	tab.add_child(match_bar)
	_admin_match_id = _match_spinbox()
	match_bar.add_child(_admin_match_id)
	var stop := Button.new()
	stop.text = "Stop Match"
	stop.pressed.connect(_stop_match)
	match_bar.add_child(stop)

	return tab


func _match_spinbox() -> SpinBox:
	var spinbox := SpinBox.new()
	spinbox.min_value = 1
	spinbox.max_value = 999999
	spinbox.value = 1
	return spinbox


func _connect_auth_signals() -> void:
	var auth := _auth()
	if auth == null:
		call_deferred("_connect_auth_signals")
		return
	auth.login_ok.connect(func(payload: Variant): message_login_ok(payload))
	auth.login_failed.connect(func(payload: Variant): message_login_failed(payload))
	auth.kicked.connect(func(payload: Variant): message_auth_kicked(payload))
	auth.logged_out.connect(message_logged_out)
	auth.not_logged_in.connect(func(): _add_line("Auth: not logged in"))
	auth.account_already_in_use.connect(func(): _add_line("Auth: account already in use"))
	auth.already_logged_in.connect(func(): _add_line("Auth: already logged in"))
	auth.forbidden.connect(func(): _add_line("Auth: forbidden"))


func _connect_to_server() -> void:
	var main = get_parent() as AlephVault__MMO__Client.Main
	if main != null:
		_add_line("Connecting to %s:%d" % [_address.text, int(_port.value)])
		main.join_server(_address.text.strip_edges(), int(_port.value))


func _disconnect_from_server() -> void:
	var main = get_parent() as AlephVault__MMO__Client.Main
	if main != null:
		main.leave_server()


func _login() -> void:
	var auth := _auth()
	if auth != null:
		auth.login("simple", {"user": _username.text, "password": _password.text})


func _logout() -> void:
	var auth := _auth()
	if auth != null:
		auth.logout()


func _me() -> void:
	var rps := _rps()
	if rps != null:
		rps.me()


func _refresh_connected_users() -> void:
	var rps := _rps()
	if rps != null:
		rps.list_connected_users()


func _refresh_users() -> void:
	var rps := _rps()
	if rps != null:
		rps.list_users()


func _propose_match() -> void:
	var rps := _rps()
	if rps != null:
		rps.propose_match(_player_target.text.strip_edges())


func _cancel_match() -> void:
	var rps := _rps()
	if rps != null:
		rps.cancel_match(int(_player_match_id.value))


func _accept_match() -> void:
	var rps := _rps()
	if rps != null:
		rps.accept_match(int(_player_match_id.value))


func _decline_match() -> void:
	var rps := _rps()
	if rps != null:
		rps.decline_match(int(_player_match_id.value))


func _play_match() -> void:
	var rps := _rps()
	if rps != null:
		rps.play_match(int(_player_match_id.value), _player_action.get_item_text(_player_action.selected))


func _reset_score() -> void:
	var rps := _rps()
	if rps != null:
		rps.reset_user_score(_admin_username.text.strip_edges())


func _set_score() -> void:
	var rps := _rps()
	if rps != null:
		rps.set_user_score(_admin_username.text.strip_edges(), int(_admin_score.value))


func _kick_user() -> void:
	var rps := _rps()
	if rps != null:
		rps.kick_user(_admin_username.text.strip_edges())


func _stop_match() -> void:
	var rps := _rps()
	if rps != null:
		rps.stop_match(int(_admin_match_id.value))


func _add_line(line: String) -> void:
	var text := _logs.text.strip_edges()
	_logs.text = line if text == "" else _logs.text + "\n" + line
	_logs.set_caret_line(max(0, _logs.get_line_count() - 1))


func _format_profile(profile: Dictionary) -> String:
	return "%s [%s] score=%s" % [profile.get("username", "?"), profile.get("role", "?"), profile.get("score", "?")]


func _set_list(target: ItemList, list: Array[Dictionary]) -> void:
	target.clear()
	for profile in list:
		target.add_item(_format_profile(profile))


func message_connection_started() -> void:
	_add_line("Connection started")


func message_connection_failed() -> void:
	_add_line("Connection failed")


func message_connection_closed() -> void:
	_add_line("Connection closed")
	_profile.text = "Profile: not logged in"


func message_login_ok(payload: Variant) -> void:
	if payload is Dictionary:
		_profile.text = "Profile: " + _format_profile(payload)
	_add_line("Login accepted")


func message_login_failed(payload: Variant) -> void:
	_add_line("Login rejected: %s" % str(payload))


func message_auth_kicked(payload: Variant) -> void:
	_add_line("Kicked: %s" % str(payload))


func message_logged_out() -> void:
	_add_line("Logged out")
	_profile.text = "Profile: not logged in"


func message_connected_users_list(list: Array[Dictionary]) -> void:
	_set_list(_connected_list, list)
	_add_line("Connected users: %d" % list.size())


func message_you(profile: Dictionary) -> void:
	_profile.text = "Profile: " + _format_profile(profile)
	_add_line("Profile refreshed")


func message_users_list(list: Array[Dictionary]) -> void:
	_set_list(_users_list, list)
	_add_line("Users: %d" % list.size())


func message_score_reset(username: String) -> void:
	_add_line("Score reset: %s" % username)


func message_score_set(username: String, score: int) -> void:
	_add_line("Score set: %s = %d" % [username, score])


func message_kicked(username: String) -> void:
	_add_line("User kicked: %s" % username)


func message_match_stopped(match_id: int, actor: String = "") -> void:
	_add_line("Match %d stopped by %s" % [match_id, actor])


func message_user_not_found(username: String) -> void:
	_add_line("User not found: %s" % username)


func message_match_not_found(match_id: int) -> void:
	_add_line("Match not found: %d" % match_id)


func message_match_proposed(match_id: int, username: String, by_you: bool) -> void:
	_add_line("Match %d proposed %s %s" % [match_id, "to" if by_you else "by", username])


func message_match_proposal_already_exists(match_id: int, username: String, by_you: bool) -> void:
	_add_line("Match proposal already exists: %d with %s" % [match_id, username])


func message_match_proposal_canceled(match_id: int, by_you: bool) -> void:
	_add_line("Match proposal %d canceled%s" % [match_id, " by you" if by_you else ""])


func message_match_proposal_declined(match_id: int, by_you: bool) -> void:
	_add_line("Match proposal %d declined%s" % [match_id, " by you" if by_you else ""])


func message_match_proposal_accepted(match_id: int, by_you: bool) -> void:
	_add_line("Match proposal %d accepted%s" % [match_id, " by you" if by_you else ""])


func message_match_play(match_id: int, by_you: bool, action: String) -> void:
	_add_line("Match %d play: %s" % [match_id, action if by_you else "opponent played"])


func message_already_played(match_id: int) -> void:
	_add_line("Already played match: %d" % match_id)


func message_match_ended(match_id: int, opponent_action: String, result: String) -> void:
	_add_line("Match %d ended: opponent=%s result=%s" % [match_id, opponent_action, result])
