extends AVMMOServerConnectionCommands

@rpc("authority", "call_remote", "reliable")
func list() -> Array[String]:
	# TODO implement.
	return []

@rpc("authority", "call_remote", "reliable")
func part() -> bool:
	# TODO implement.
	return false

@rpc("authority", "call_remote", "reliable")
func join(channel: String) -> bool:
	# TODO implement.
	return false

@rpc("authority", "call_remote", "reliable")
func send(message: String):
	# TODO implement.
	pass

@rpc("authority", "call_remote", "reliable")
func nick(nickname: String) -> bool:
	# TODO implement.
	return false
