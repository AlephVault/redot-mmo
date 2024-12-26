extends AVMMOServerConnectionNotifications

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
