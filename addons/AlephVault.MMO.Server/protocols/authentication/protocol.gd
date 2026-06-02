extends AlephVault__MMO__Server.Protocols.Protocol

## Emitted after a session is created and the client is notified that login
## succeeded.
##
## account_data is the value returned by _find_account() for the accepted
## account id.
signal session_starting(connection_id: int, account_data: Variant)

## Emitted immediately before an existing session is removed.
##
## reason is the logout, kick, or disconnection reason passed to
## _terminate_session().
signal session_terminating(connection_id: int, reason: Variant)

## Emitted when the authentication flow cannot continue because of a server-side
## error at a known session stage.
signal session_error(connection_id: int, stage: String, error: Variant)

## Prefix reserved for internal keys stored in per-session data dictionaries.
##
## clear_session_data() preserves keys with this prefix.
const INTERNAL_SESSION_PREFIX := "__AV:MMO:AUTH__"

## Active sessions indexed by multiplayer connection id.
##
## Each value is a Dictionary containing "connection_id", "account_id", and "account_data".
var _sessions_by_connection_id: Dictionary = {}

## Active connection ids grouped by authenticated account id.
var _sessions_by_account_id: Dictionary = {}

## Creates the server commands RPC node used to receive authentication requests
## from clients.
func _create_commands_node() -> AlephVault__MMO__Server.Protocols.Commands:
	return AlephVault__MMO__Server.Protocols.Authentication.Commands.new()

## Creates the server notifications RPC node used to send authentication
## responses to clients.
func _create_notifications_node() -> AlephVault__MMO__Server.Protocols.Notifications:
	return AlephVault__MMO__Server.Protocols.Authentication.Notifications.new()

## Terminates an authenticated session when its client disconnects without a
## graceful logout.
func client_left(id: int) -> void:
	if session_exists(id):
		_terminate_session(id, AlephVault__MMO__Common.Protocols.Authentication.KickReasons.non_graceful_disconnection(), false)

## Authenticates a login request.
##
## Override this method in a concrete server protocol. It may return
## immediately or await asynchronous work. Return
## AlephVault__MMO__Common.Protocols.Authentication.LoginResult.accept() with an
## account id to accept the login, or LoginResult.reject() to reject it.
func _authenticate(connection_id: int, method: String, payload: Variant) -> Dictionary:
	return AlephVault__MMO__Common.Protocols.Authentication.LoginResult.reject({
		"reason": "not_implemented",
		"method": method,
		"connection_id": connection_id,
	})

## Loads account data for an accepted account id.
##
## Override this method to return the account/session data that session_starting
## listeners need. It may return immediately or await asynchronous work.
## Returning null aborts the login and kicks the client with an account load
## error.
func _find_account(account_id: Variant) -> Variant:
	return null

## Returns how the protocol handles a login for an account that already has an
## active session.
##
## Override this to return one of
## AccountAlreadyLoggedManagementMode.GHOST, REJECT, or ALLOW_ALL.
func _if_account_already_logged_in() -> int:
	return AlephVault__MMO__Common.Protocols.Authentication.AccountAlreadyLoggedManagementMode.REJECT

## Handles a client login RPC request.
##
## This checks duplicate sessions, authenticates the request, applies the
## account-already-logged-in policy, loads account data, creates the session,
## notifies the client, and emits session_starting.
func handle_login_requested(connection_id: int, method: String, payload: Variant = null) -> void:
	if session_exists(connection_id):
		_send_already_logged_in(connection_id)
		return

	var result: Dictionary = await _authenticate(connection_id, method, payload)
	if session_exists(connection_id):
		_send_already_logged_in(connection_id)
		return
	if not AlephVault__MMO__Common.Protocols.Authentication.LoginResult.is_accepted(result):
		_send_login_failed(connection_id, result.get("failed"))
		_close_connection(connection_id)
		return

	var account_id: Variant = result.get("account_id")
	var mode := _if_account_already_logged_in()
	if _is_rejected_by_account_policy(connection_id, account_id, mode):
		return
	if mode == AlephVault__MMO__Common.Protocols.Authentication.AccountAlreadyLoggedManagementMode.GHOST:
		kick(account_id, AlephVault__MMO__Common.Protocols.Authentication.KickReasons.ghosted())

	var account_data: Variant = await _find_account(account_id)
	if session_exists(connection_id):
		_send_already_logged_in(connection_id)
		return
	if _is_rejected_by_account_policy(connection_id, account_id, mode):
		return
	if mode == AlephVault__MMO__Common.Protocols.Authentication.AccountAlreadyLoggedManagementMode.GHOST:
		kick(account_id, AlephVault__MMO__Common.Protocols.Authentication.KickReasons.ghosted())
	if account_data == null:
		session_error.emit(
			connection_id,
			AlephVault__MMO__Common.Protocols.Authentication.SessionStage.ACCOUNT_LOAD,
			{"account_id": account_id}
		)
		_send_kicked(connection_id, AlephVault__MMO__Common.Protocols.Authentication.KickReasons.account_load_error())
		_close_connection(connection_id)
		return

	_add_session(connection_id, account_id)
	_send_login_ok(connection_id, result.get("ok"))
	session_starting.emit(connection_id, account_data)

## Applies the active duplicate-account policy before a session is created.
##
## Returns true when the login request has been rejected and fully handled.
func _is_rejected_by_account_policy(connection_id: int, account_id: Variant, mode: int) -> bool:
	if mode == AlephVault__MMO__Common.Protocols.Authentication.AccountAlreadyLoggedManagementMode.REJECT and _sessions_by_account_id.has(account_id):
		_send_account_already_in_use(connection_id)
		_close_connection(connection_id)
		return true
	return false

## Handles a client logout RPC request.
##
## Sends not_logged_in when no session exists. Otherwise, notifies the client and
## terminates the session.
func handle_logout_requested(connection_id: int) -> void:
	if not session_exists(connection_id):
		_send_not_logged_in(connection_id)
		return
	_send_logged_out(connection_id)
	_terminate_session(connection_id, null)

## Kicks every active session for an account id.
func kick(account_id: Variant, reason: Variant = null) -> void:
	if not _sessions_by_account_id.has(account_id):
		return
	var connection_ids: Array = []
	connection_ids.assign(_sessions_by_account_id[account_id].keys())
	for connection_id in connection_ids:
		kick_connection(connection_id, reason)

## Kicks one active connection by id.
##
## If reason is null, a default server_kick reason is sent to the client.
func kick_connection(connection_id: int, reason: Variant = null) -> void:
	if not session_exists(connection_id):
		return
	_send_kicked(connection_id, reason if reason != null else AlephVault__MMO__Common.Protocols.Authentication.KickReasons.server_kick())
	_terminate_session(connection_id, reason)

## Runs an action only when the connection has an authenticated session.
##
## If the session is missing, sends not_logged_in and returns null. If allowed
## is valid and returns false for the connection id, sends forbidden and returns
## null. Otherwise, calls action with the connection id and returns its result.
## Both allowed and action may return immediately or await asynchronous work.
func login_required(connection_id: int, action: Callable, allowed: Callable = Callable()) -> Variant:
	if not session_exists(connection_id):
		_send_not_logged_in(connection_id)
		return null
	if allowed.is_valid():
		var allowed_result: Variant = await allowed.call(connection_id)
		if not session_exists(connection_id):
			_send_not_logged_in(connection_id)
			return null
		if not bool(allowed_result):
			_send_forbidden(connection_id)
			return null
	return await action.call(connection_id)

## Runs an action only when the connection does not have an authenticated
## session.
##
## If a session already exists, sends already_logged_in and returns null.
## Otherwise, calls action with the connection id and returns its result.
## The action may return immediately or await asynchronous work.
func logout_required(connection_id: int, action: Callable) -> Variant:
	if session_exists(connection_id):
		_send_already_logged_in(connection_id)
		return null
	return await action.call(connection_id)

## Returns whether the connection has an authenticated session.
func session_exists(connection_id: int) -> bool:
	return _sessions_by_connection_id.has(connection_id)

## Returns the authenticated account id for a connection.
##
## Fails an assertion when the session does not exist.
func get_session_account_id(connection_id: int) -> Variant:
	_assert_session_exists(connection_id)
	return _sessions_by_connection_id[connection_id]["account_id"]

## Stores a value in the connection's session data dictionary.
##
## Fails an assertion when the session does not exist.
func set_session_data(connection_id: int, key: String, value: Variant) -> void:
	_assert_session_exists(connection_id)
	_sessions_by_connection_id[connection_id]["account_data"][key] = value

## Returns a value from the connection's session data dictionary, or
## default_value when the key is missing.
##
## Fails an assertion when the session does not exist.
func get_session_data(connection_id: int, key: String, default_value: Variant = null) -> Variant:
	_assert_session_exists(connection_id)
	return _sessions_by_connection_id[connection_id]["account_data"].get(key, default_value)

## Removes a key from the connection's session data dictionary.
##
## Returns true when the key existed. Fails an assertion when the session does
## not exist.
func remove_session_data(connection_id: int, key: String) -> bool:
	_assert_session_exists(connection_id)
	return _sessions_by_connection_id[connection_id]["account_data"].erase(key)

## Clears data stored in the connection's session data dictionary.
##
## When user_data_only is true, keys starting with INTERNAL_SESSION_PREFIX are
## preserved. Fails an assertion when the session does not exist.
func clear_session_data(connection_id: int) -> void:
	_assert_session_exists(connection_id)
	var data: Dictionary = _sessions_by_connection_id[connection_id]["account_data"]
	for key in data.keys():
		if not str(key).begins_with(INTERNAL_SESSION_PREFIX):
			data.erase(key)

## Returns whether the connection's session data dictionary contains key.
##
## Fails an assertion when the session does not exist.
func session_contains_key(connection_id: int, key: String) -> bool:
	_assert_session_exists(connection_id)
	return _sessions_by_connection_id[connection_id]["account_data"].has(key)

## Creates a session for a connection and account id.
##
## This updates both session indexes. Existing entries for the same connection
## id are overwritten.
func _add_session(connection_id: int, account_id: Variant) -> void:
	var session := {"connection_id": connection_id, "account_id": account_id, "account_data": {}}
	_sessions_by_connection_id[connection_id] = session
	if not _sessions_by_account_id.has(account_id):
		_sessions_by_account_id[account_id] = {}
	_sessions_by_account_id[account_id][connection_id] = true

## Removes a session from both session indexes.
##
## Missing connection ids are ignored.
func _remove_session(connection_id: int) -> void:
	if not _sessions_by_connection_id.has(connection_id):
		return
	var account_id: Variant = _sessions_by_connection_id[connection_id]["account_id"]
	_sessions_by_connection_id.erase(connection_id)
	if _sessions_by_account_id.has(account_id):
		_sessions_by_account_id[account_id].erase(connection_id)
		if _sessions_by_account_id[account_id].is_empty():
			_sessions_by_account_id.erase(account_id)

## Emits session_terminating, removes the session, and optionally closes the
## connection.
##
## Missing sessions are ignored.
func _terminate_session(connection_id: int, reason: Variant, close_after: bool = true) -> void:
	if not session_exists(connection_id):
		return
	session_terminating.emit(connection_id, reason)
	_remove_session(connection_id)
	if close_after:
		_close_connection(connection_id)

## Fails an assertion when the connection does not have an authenticated
## session.
func _assert_session_exists(connection_id: int) -> void:
	assert(session_exists(connection_id), "Trying to access a missing authentication session")

## Sends a successful-login notification to a client.
func _send_login_ok(connection_id: int, payload: Variant = null) -> void:
	notify(connection_id, "login_ok", [payload])

## Sends a failed-login notification to a client.
func _send_login_failed(connection_id: int, payload: Variant = null) -> void:
	notify(connection_id, "login_failed", [payload])

## Sends a kick notification to a client.
func _send_kicked(connection_id: int, payload: Variant = null) -> void:
	notify(connection_id, "kicked", [payload])

## Sends a logout confirmation notification to a client.
func _send_logged_out(connection_id: int) -> void:
	notify(connection_id, "logged_out")

## Sends a not-logged-in notification to a client.
func _send_not_logged_in(connection_id: int) -> void:
	notify(connection_id, "not_logged_in")

## Sends an account-already-in-use notification to a client.
func _send_account_already_in_use(connection_id: int) -> void:
	notify(connection_id, "account_already_in_use")

## Sends an already-logged-in notification to a client.
func _send_already_logged_in(connection_id: int) -> void:
	notify(connection_id, "already_logged_in")

## Sends a forbidden notification to a client.
func _send_forbidden(connection_id: int) -> void:
	notify(connection_id, "forbidden")

## Disconnects a client from the server when the multiplayer peer is available.
func _close_connection(connection_id: int) -> void:
	var main = get_parent().get_parent() as AlephVault__MMO__Server.Main
	if main != null and is_instance_valid(main.multiplayer.multiplayer_peer):
		main.multiplayer.multiplayer_peer.disconnect_peer(connection_id)
