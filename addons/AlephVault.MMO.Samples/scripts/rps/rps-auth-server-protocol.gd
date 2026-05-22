extends AlephVault__MMO__Server.Protocols.Authentication.Protocol


const ROLE_PLAYER := "player"
const ROLE_ADMIN := "admin"

var _users: Array[Dictionary] = [
	{"username": "foo", "password": "foo1", "role": ROLE_PLAYER, "score": 0},
	{"username": "bar", "password": "bar1", "role": ROLE_PLAYER, "score": 0},
	{"username": "baz", "password": "baz1", "role": ROLE_PLAYER, "score": 0},
	{"username": "qoo", "password": "qoo1", "role": ROLE_PLAYER, "score": 0},
	{"username": "admin", "password": "admin1", "role": ROLE_ADMIN, "score": 0},
]

var _connected_profiles_by_connection_id: Dictionary = {}


func _ready() -> void:
	session_starting.connect(_on_session_starting)
	session_terminating.connect(_on_session_terminating)


func _authenticate(connection_id: int, method: String, payload: Variant) -> Dictionary:
	if not payload is Dictionary:
		return AlephVault__MMO__Common.Protocols.Authentication.LoginResult.reject({"reason": "invalid_payload"})
	if not payload.has("user") or not payload.has("password"):
		return AlephVault__MMO__Common.Protocols.Authentication.LoginResult.reject({"reason": "missing_credentials"})

	var username := str(payload["user"]).strip_edges()
	var password := str(payload["password"])
	var user := find_user(username)
	if user.is_empty() or str(user["password"]) != password:
		return AlephVault__MMO__Common.Protocols.Authentication.LoginResult.reject({"reason": "invalid_credentials"})

	return AlephVault__MMO__Common.Protocols.Authentication.LoginResult.accept(profile_without_password(user), str(user["username"]).to_lower())


func _find_account(account_id: Variant) -> Variant:
	var user := find_user(str(account_id))
	if user.is_empty():
		return null
	return profile_without_password(user)


func find_user(username: String) -> Dictionary:
	var needle := username.strip_edges().to_lower()
	for user in _users:
		if str(user["username"]).to_lower() == needle:
			return user
	return {}


func profile_without_password(user: Dictionary) -> Dictionary:
	return {
		"username": user["username"],
		"role": user["role"],
		"score": user["score"],
	}


func get_profile(username: String) -> Dictionary:
	var user := find_user(username)
	if user.is_empty():
		return {}
	return profile_without_password(user)


func list_profiles() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for user in _users:
		result.append(profile_without_password(user))
	return result


func get_connected_profiles() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for profile in _connected_profiles_by_connection_id.values():
		result.append(profile.duplicate())
	return result


func get_connected_profile(connection_id: int) -> Dictionary:
	return _connected_profiles_by_connection_id.get(connection_id, {})


func get_connected_connection_id(username: String) -> int:
	var needle := username.strip_edges().to_lower()
	for connection_id in _connected_profiles_by_connection_id.keys():
		var profile: Dictionary = _connected_profiles_by_connection_id[connection_id]
		if str(profile["username"]).to_lower() == needle:
			return int(connection_id)
	return 0


func set_score(username: String, score: int) -> bool:
	var user := find_user(username)
	if user.is_empty():
		return false
	user["score"] = score
	_update_connected_profile(str(user["username"]))
	return true


func add_score(username: String, delta: int) -> bool:
	var user := find_user(username)
	if user.is_empty():
		return false
	user["score"] = int(user["score"]) + delta
	_update_connected_profile(str(user["username"]))
	return true


func _update_connected_profile(username: String) -> void:
	var connection_id := get_connected_connection_id(username)
	if connection_id != 0:
		_connected_profiles_by_connection_id[connection_id] = get_profile(username)


func _on_session_starting(connection_id: int, account_data: Variant) -> void:
	if account_data is Dictionary:
		_connected_profiles_by_connection_id[connection_id] = account_data.duplicate()


func _on_session_terminating(connection_id: int, reason: Variant) -> void:
	_connected_profiles_by_connection_id.erase(connection_id)
