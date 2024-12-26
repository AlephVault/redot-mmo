extends AVMMOClientConnectionNotifications

@rpc("authority", "call_remote", "reliable")
func user_join(connection_id: int, nick: String):
	# TODO implement.
	pass

@rpc("authority", "call_remote", "reliable")
func user_part(connection_id: int, nick: String) -> bool:
	# TODO implement.
	return false

@rpc("authority", "call_remote", "reliable")
func user_sent(message: String) -> bool:
	# TODO implement.
	return false

@rpc("authority", "call_remote", "reliable")
func user_nick(nick: String):
	# TODO implement.
	pass
