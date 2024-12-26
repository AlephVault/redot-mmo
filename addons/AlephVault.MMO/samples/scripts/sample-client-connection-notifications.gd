extends AVMMOClientConnectionNotifications

@rpc("authority", "call_remote", "reliable")
func user_join(connection_id: int, nick: String):
	$"../../..".client_ui.message_user_join(connection_id, nick)

@rpc("authority", "call_remote", "reliable")
func user_part(connection_id: int, nick: String):
	$"../../..".client_ui.message_user_part(connection_id, nick)

@rpc("authority", "call_remote", "reliable")
func user_sent(connection_id: int, nick: String, message: String):
	$"../../..".client_ui.message_user_sent(connection_id, nick, message)

@rpc("authority", "call_remote", "reliable")
func user_nick(connection_id: int, nick: String, new_nick: String):
	$"../../..".client_ui.message_user_nickn(connection_id, nick, new_nick)
