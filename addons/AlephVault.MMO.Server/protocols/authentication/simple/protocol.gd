extends AlephVault__MMO__Server.Protocols.Authentication.Protocol

## The signal triggered when a profile is selected (automatically or
## by the user). The connection id is specified, and the profile data
## is already available for querying via session profile data methods.
signal profile_starting(connection_id: int)

## The signal triggered after a selected profile is closed or forcibly stopped.
##
## The connection has already been moved back to the account dashboard scope.
signal profile_terminating(connection_id: int)

static var _MONOPROFILE_ID = Object.new()
static var _MONOPROFILE_DATA = Object.new()

const PROFILE_STATUS_OK := "ok"
const PROFILE_STATUS_INVALID := "invalid"
const PROFILE_STATUS_UNAVAILABLE := "unavailable"
const PROFILE_STATUS_AVAILABLE := "available"

const OK := 0
const NO_ACCOUNT := 1
const MONOPROFILE := 2
const NO_PROFILE_SELECTED := 3

const PROFILE_CLOSE_REASON_MONOPROFILE := "monoprofile"
const PROFILE_CLOSE_REASON_NOT_SELECTED := "not_selected"

func _ready() -> void:
	session_starting.connect(_on_session_starting)

func _create_commands_node() -> AlephVault__MMO__Server.Protocols.Commands:
	return AlephVault__MMO__Server.Protocols.Authentication.Simple.Commands.new()

func _create_notifications_node() -> AlephVault__MMO__Server.Protocols.Notifications:
	return AlephVault__MMO__Server.Protocols.Authentication.Simple.Notifications.new()

## Override this method to tell apart whether an account is
## multi-profile or not. In a same game, there might be types
## of accounts which are multi-profile (e.g. players) vs others
## which are mono-profile (e.g. admin observers, not players).
func _is_account_multiprofile(account_data: Variant) -> bool:
	return false

## Override this method to return the profile previews available to an account.
##
## The returned values are sent to the client with profiles_list. They are not
## expected to be complete profile data.
func _list_account_profile_previews(account_id: Variant) -> Array[Variant]:
	return []

## Override this method to load complete profile data for an account profile id.
##
## Return a Dictionary with status "ok", "invalid", or "unavailable". On
## success, include "profile_data". On failure, include "reason". The literal
## status "available" is also treated as unavailable for compatibility with
## early profile result shapes.
func _get_account_profile_data(account_id: Variant, profile_id: Variant) -> Dictionary:
	return {
		"status": PROFILE_STATUS_INVALID,
		"reason": "not_implemented",
		"profile_data": null,
	}

## Override this method to choose what profile data is sent to the client after
## a profile is selected.
##
## The default implementation returns the complete profile data unchanged.
func _get_profile_user_view(profile_data: Variant) -> Variant:
	return profile_data

func _on_session_starting(connection_id: int, account_data: Variant) -> void:
	var is_multi_profile: bool = await _is_account_multiprofile(account_data)
	if not session_exists(connection_id):
		return
	if not is_multi_profile:
		_set_profile(connection_id, _MONOPROFILE_ID, _MONOPROFILE_DATA)
		profile_starting.emit(connection_id)
		return

	var account_id: Variant = get_session_account_id(connection_id)
	var profiles: Array[Variant] = await _list_account_profile_previews(account_id)
	if not session_exists(connection_id):
		return
	_move_connection_to_account_dashboard(connection_id)
	_send_profiles_list(connection_id, profiles)

func _set_profile(connection_id: int, profile_id: Variant, profile_data: Variant) -> void:
	_assert_session_exists(connection_id)
	_sessions_by_connection_id[connection_id]["profile_id"] = profile_id
	_sessions_by_connection_id[connection_id]["profile_data"] = profile_data

func _move_connection_to_account_dashboard(connection_id: int) -> void:
	var manager = get_parent() as AlephVault__MMO__Server.Protocols.Manager
	if manager == null:
		return
	var main = manager.get_parent() as AlephVault__MMO__Server.Main
	if main == null or main.connections == null or not main.connections.has_connection(connection_id):
		return
	main.connections.set_connection_scope(
		connection_id,
		_account_dashboard_scope_id()
	)

func handle_list_profiles_requested(connection_id: int) -> void:
	await login_required(
		connection_id,
		func(id: int):
			return await _refresh_account_profile_previews(id),
		Callable(self, "_is_connection_in_account_dashboard")
	)

func handle_select_profile_requested(connection_id: int, profile_id: Variant) -> void:
	await login_required(
		connection_id,
		func(id: int):
			return await _select_account_profile(id, profile_id),
		Callable(self, "_is_connection_in_account_dashboard")
	)

func handle_close_profile_requested(connection_id: int) -> void:
	var result := kick_profile(connection_id, null)
	if result == NO_ACCOUNT:
		_send_not_logged_in(connection_id)
	elif result == MONOPROFILE:
		_send_profile_not_closeable(connection_id, PROFILE_CLOSE_REASON_MONOPROFILE)
	elif result == NO_PROFILE_SELECTED:
		_send_profile_not_selected(connection_id, PROFILE_CLOSE_REASON_NOT_SELECTED)

func _send_profiles_list(connection_id: int, profiles: Array[Variant]) -> bool:
	return notify(connection_id, "profiles_list", [profiles])

func _send_profile_invalid(connection_id: int, reason: Variant) -> bool:
	return notify(connection_id, "profile_invalid", [reason])

func _send_profile_unavailable(connection_id: int, reason: Variant) -> bool:
	return notify(connection_id, "profile_unavailable", [reason])

func _send_profile_selected(connection_id: int, profile_id: Variant, profile: Variant) -> bool:
	return notify(connection_id, "profile_selected", [profile_id, profile])

func _send_profile_closed(connection_id: int, reason: Variant = null) -> bool:
	return notify(connection_id, "profile_closed", [reason])

func _send_profile_not_selected(connection_id: int, reason: Variant = null) -> bool:
	return notify(connection_id, "profile_not_selected", [reason])

func _send_profile_not_closeable(connection_id: int, reason: Variant = null) -> bool:
	return notify(connection_id, "profile_not_closeable", [reason])

func _refresh_account_profile_previews(connection_id: int) -> void:
	var account_id: Variant = get_session_account_id(connection_id)
	var profiles: Array[Variant] = await _list_account_profile_previews(account_id)
	if not session_exists(connection_id) or not _is_connection_in_account_dashboard(connection_id):
		return
	_send_profiles_list(connection_id, profiles)

func _select_account_profile(connection_id: int, profile_id: Variant) -> void:
	var account_id: Variant = get_session_account_id(connection_id)
	var result: Dictionary = await _get_account_profile_data(account_id, profile_id)
	if not session_exists(connection_id) or not _is_connection_in_account_dashboard(connection_id):
		return

	if _profile_result_is_invalid(result):
		_send_profile_invalid(connection_id, _profile_result_reason(result))
		return
	if _profile_result_is_unavailable(result):
		_send_profile_unavailable(connection_id, _profile_result_reason(result))
		return
	if not _profile_result_is_ok(result):
		_send_profile_invalid(connection_id, _profile_result_reason(result))
		return

	var profile_data: Variant = result.get("profile_data")
	_set_profile(connection_id, profile_id, profile_data)
	_send_profile_selected(connection_id, profile_id, await _get_profile_user_view(profile_data))
	profile_starting.emit(connection_id)

## Closes or forcibly stops the selected profile for a multi-profile session.
##
## reason is sent to the client with profile_closed. A null reason means a
## graceful close. Returns OK, NO_ACCOUNT, MONOPROFILE, or NO_PROFILE_SELECTED.
## Error statuses do not send notifications to the target connection.
func kick_profile(connection_id: int, reason: Variant = null) -> int:
	if not session_exists(connection_id):
		return NO_ACCOUNT
	if _session_has_monoprofile(connection_id):
		return MONOPROFILE
	if not _session_has_selected_profile(connection_id):
		return NO_PROFILE_SELECTED

	_clear_profile(connection_id)
	_send_profile_closed(connection_id, reason)
	_move_connection_to_account_dashboard(connection_id)
	profile_terminating.emit(connection_id)
	return OK

func _profile_result_is_ok(result: Dictionary) -> bool:
	return result.get("status") == PROFILE_STATUS_OK

func _profile_result_is_invalid(result: Dictionary) -> bool:
	return result.get("status") == PROFILE_STATUS_INVALID

func _profile_result_is_unavailable(result: Dictionary) -> bool:
	var status: Variant = result.get("status")
	return status == PROFILE_STATUS_UNAVAILABLE or status == PROFILE_STATUS_AVAILABLE

func _profile_result_reason(result: Dictionary) -> Variant:
	return result.get("reason")

func _clear_profile(connection_id: int) -> void:
	_set_profile(connection_id, null, null)

func _session_has_monoprofile(connection_id: int) -> bool:
	return _sessions_by_connection_id[connection_id]["profile_id"] == _MONOPROFILE_ID

func _session_has_selected_profile(connection_id: int) -> bool:
	var profile_id: Variant = _sessions_by_connection_id[connection_id]["profile_id"]
	return profile_id != null and profile_id != _MONOPROFILE_ID

func _is_connection_in_account_dashboard(connection_id: int) -> bool:
	var manager = get_parent() as AlephVault__MMO__Server.Protocols.Manager
	if manager == null:
		return false
	var main = manager.get_parent() as AlephVault__MMO__Server.Main
	if main == null or main.connections == null or not main.connections.has_connection(connection_id):
		return false
	return main.connections.get_connection_scope(connection_id) == _account_dashboard_scope_id()

func _account_dashboard_scope_id() -> int:
	return AlephVault__MMO__Common.Scopes.make_fq_special_scope_id(
		AlephVault__MMO__Common.Scopes.SCOPE_ACCOUNT_DASHBOARD
	)

## Stores a value in the selected profile data dictionary.
##
## Fails an assertion when the session does not exist. Does nothing when the
## session is mono-profile, has no selected profile, or the selected profile
## data is not a Dictionary.
func set_session_profile_data(connection_id: int, key: String, value: Variant) -> void:
	_assert_session_exists(connection_id)
	if not _session_has_selected_profile_data(connection_id):
		return
	_sessions_by_connection_id[connection_id]["profile_data"][key] = value

## Returns a value from the selected profile data dictionary.
##
## Returns default_value when the key is missing, the session is mono-profile,
## has no selected profile, or the selected profile data is not a Dictionary.
## Fails an assertion when the session does not exist.
func get_session_profile_data(connection_id: int, key: String, default_value: Variant = null) -> Variant:
	_assert_session_exists(connection_id)
	if not _session_has_selected_profile_data(connection_id):
		return default_value
	return _sessions_by_connection_id[connection_id]["profile_data"].get(key, default_value)

## Removes a key from the selected profile data dictionary.
##
## Returns true when the key existed. Returns false when the session is
## mono-profile, has no selected profile, or the selected profile data is not a
## Dictionary. Fails an assertion when the session does not exist.
func remove_session_profile_data(connection_id: int, key: String) -> bool:
	_assert_session_exists(connection_id)
	if not _session_has_selected_profile_data(connection_id):
		return false
	return _sessions_by_connection_id[connection_id]["profile_data"].erase(key)

## Clears user data stored in the selected profile data dictionary.
##
## Keys starting with INTERNAL_SESSION_PREFIX are preserved. Fails an assertion
## when the session does not exist. Does nothing when the session is
## mono-profile, has no selected profile, or the selected profile data is not a
## Dictionary.
func clear_session_profile_data(connection_id: int) -> void:
	_assert_session_exists(connection_id)
	if not _session_has_selected_profile_data(connection_id):
		return
	var data: Dictionary = _sessions_by_connection_id[connection_id]["profile_data"]
	for key in data.keys():
		if not str(key).begins_with(INTERNAL_SESSION_PREFIX):
			data.erase(key)

## Returns whether the selected profile data dictionary contains key.
##
## Returns false when the session is mono-profile, has no selected profile, or
## the selected profile data is not a Dictionary. Fails an assertion when the
## session does not exist.
func session_profile_contains_key(connection_id: int, key: String) -> bool:
	_assert_session_exists(connection_id)
	if not _session_has_selected_profile_data(connection_id):
		return false
	return _sessions_by_connection_id[connection_id]["profile_data"].has(key)

func _session_has_selected_profile_data(connection_id: int) -> bool:
	if not _session_has_selected_profile(connection_id):
		return false
	return _sessions_by_connection_id[connection_id]["profile_data"] is Dictionary
