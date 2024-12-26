extends AVMMOClientConnectionCommands

@rpc("authority", "call_remote", "reliable")
func list() -> Array[String]:
	return []

@rpc("authority", "call_remote", "reliable")
func part() -> bool:
	return false

@rpc("authority", "call_remote", "reliable")
func join(channel: String) -> bool:
	return false

@rpc("authority", "call_remote", "reliable")
func send(message: String):
	pass

@rpc("authority", "call_remote", "reliable")
func nick(nickname: String) -> bool:
	return false
