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
	$"../../..".client_ui.message_user_nick(connection_id, nick, new_nick)

@rpc("authority", "call_remote", "reliable")
func nick_result(nick: String, result: bool):
	$"../../..".client_ui.message_nick_result(nick, result)

@rpc("authority", "call_remote", "reliable")
func list_result(result: Array[String]):
	$"../../..".client_ui.message_list_result(result)

@rpc("authority", "call_remote", "reliable")
func join_result(channel: String, result: bool):
	$"../../..".client_ui.message_join_result(channel, result)

@rpc("authority", "call_remote", "reliable")
func part_result(result: bool):
	$"../../..".client_ui.message_join_result(result)
