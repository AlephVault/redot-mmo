extends AlephVault__MMO__Client.Protocols.Protocol


const AuthProtocol = preload("./rps-auth-client-protocol.gd")
const Commands = preload("./rps-client-commands.gd")
const Notifications = preload("./rps-client-notifications.gd")


static func _get_dependencies() -> Array[Script]:
	return [AuthProtocol]


func _create_commands_node() -> AlephVault__MMO__Client.Protocols.Commands:
	return Commands.new()


func _create_notifications_node() -> AlephVault__MMO__Client.Protocols.Notifications:
	return Notifications.new()


func list_connected_users() -> bool:
	return command("list_connected_users")


func me() -> bool:
	return command("me")


func list_users() -> bool:
	return command("list_users")


func reset_user_score(username: String) -> bool:
	return command("reset_user_score", [username])


func set_user_score(username: String, score: int) -> bool:
	return command("set_user_score", [username, score])


func kick_user(username: String) -> bool:
	return command("kick_user", [username])


func stop_match(match_id: int) -> bool:
	return command("stop_match", [match_id])


func propose_match(username: String) -> bool:
	return command("propose_match", [username])


func cancel_match(match_id: int) -> bool:
	return command("cancel_match", [match_id])


func accept_match(match_id: int) -> bool:
	return command("accept_match", [match_id])


func decline_match(match_id: int) -> bool:
	return command("decline_match", [match_id])


func play_match(match_id: int, action: String) -> bool:
	return command("play_match", [match_id, action])
