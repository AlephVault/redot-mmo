extends Control


## Sets the nickname via command.
func set_nickname():
	var nickname = %NewNickname.text.strip_edges()
	# TODO: Actually set the nickname.


## Sends the current command.
func send_command():
	var command: String = %Command.text.strip_edges()
	var command_parts = command.split(" ", false, 1)
	var base_command: String = command_parts[0].to_lower()
	var argument = command_parts[1]
	if base_command == "/join":
		# Change the current channel.
		pass
	elif base_command == "/part":
		# Leaves the current channel, if any.
		pass
	elif base_command == "/nick":
		# Changes the nick.
		pass
	elif base_command == "/list":
		# Lists the channels.
		pass
	else:
		# Sends a message.
		pass
