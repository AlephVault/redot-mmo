extends AlephVault__MMO__Server.Protocols.Authentication.Protocol

## The signal triggered when a profile is selected (automatically or
## by the user). The connection id is specified, and the profile data
## is already available for querying via session profile data methods.
signal profile_starting(connection_id: int)

static var _MONOPROFILE_ID = Object.new()
static var _MONOPROFILE_DATA = Object.new()

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
	send_profiles_list(connection_id, profiles)

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
		AlephVault__MMO__Common.Scopes.make_fq_special_scope_id(
			AlephVault__MMO__Common.Scopes.SCOPE_ACCOUNT_DASHBOARD
		)
	)

func handle_list_profiles_requested(connection_id: int) -> void:
	pass

func handle_select_profile_requested(connection_id: int, profile_id: Variant) -> void:
	pass

func handle_close_profile_requested(connection_id: int) -> void:
	pass

func send_profiles_list(connection_id: int, profiles: Array[Variant]) -> bool:
	return notify(connection_id, "profiles_list", [profiles])

func send_profile_invalid(connection_id: int, reason: Variant) -> bool:
	return notify(connection_id, "profile_invalid", [reason])

func send_profile_unavailable(connection_id: int, reason: Variant) -> bool:
	return notify(connection_id, "profile_unavailable", [reason])

func send_profile_selected(connection_id: int, profile: Variant) -> bool:
	return notify(connection_id, "profile_selected", [profile])

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
	var profile_id: Variant = _sessions_by_connection_id[connection_id]["profile_id"]
	if profile_id == null or profile_id == _MONOPROFILE_ID:
		return false
	return _sessions_by_connection_id[connection_id]["profile_data"] is Dictionary
