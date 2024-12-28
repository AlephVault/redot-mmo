extends AlephVault__MMO.Server.ConnectionNotifications

@rpc("authority", "call_remote", "reliable")
func user_join(connection_id: int, nick: String):
	pass

@rpc("authority", "call_remote", "reliable")
func user_part(connection_id: int, nick: String):
	return false

@rpc("authority", "call_remote", "reliable")
func user_sent(connection_id: int, nick: String, message: String):
	return false

@rpc("authority", "call_remote", "reliable")
func user_nick(connection_id: int, nick: String, new_nick: String):
	pass

@rpc("authority", "call_remote", "reliable")
func nick_result(nick: String, result: bool):
	pass

@rpc("authority", "call_remote", "reliable")
func list_result(result: Array[String]):
	pass

@rpc("authority", "call_remote", "reliable")
func join_result(channel: String, result: bool):
	pass

@rpc("authority", "call_remote", "reliable")
func part_result(result: bool):
	pass
