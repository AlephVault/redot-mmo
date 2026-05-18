extends AlephVault__MMO__Client.ProtocolCommands

func _enter_tree() -> void:
	print("Client protocol commands path:", get_path())

@rpc("authority", "call_remote", "reliable")
func list():
	return []

@rpc("authority", "call_remote", "reliable")
func part():
	return false

@rpc("authority", "call_remote", "reliable")
func join(channel: String):
	return false

@rpc("authority", "call_remote", "reliable")
func send(message: String):
	pass

@rpc("authority", "call_remote", "reliable")
func nick(nickname: String):
	return false
