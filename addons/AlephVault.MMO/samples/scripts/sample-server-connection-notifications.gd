extends AVMMOServerConnectionNotifications

@rpc("authority", "call_remote", "reliable")
func user_join(connection_id: int, nick: String):
	pass

@rpc("authority", "call_remote", "reliable")
func user_part(connection_id: int, nick: String) -> bool:
	return false

@rpc("authority", "call_remote", "reliable")
func user_sent(message: String) -> bool:
	return false

@rpc("authority", "call_remote", "reliable")
func user_nick(nick: String):
	pass
