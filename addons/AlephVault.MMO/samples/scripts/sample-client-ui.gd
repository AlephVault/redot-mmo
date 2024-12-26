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

func _add_line(line: String):
	var text: String = %Message.text
	var new_text: String = line
	if text.strip_edges() != "":
		new_text = text + "\n" + line
	%Message.text = new_text

func _clear():
	%Message.text = ""

func message_connection_started():
	_add_line("## Connection started")

func message_connection_failed():
	_add_line("## Connection failed")

func message_connection_closed():
	_add_line("## Connection closed")

func message_scope_changed(id: int):
	_add_line("## [DEBUG] Scope changed: %d" % id)

func message_local_nick(nick: String, result: bool):
	if result:
		_add_line("** Nick updated successfully: " + nick)
	else:
		_add_line("** ! Could not update nick: " + nick)

func message_local_list(result: Array[String]):
	_add_line("** Available channels: " + ", ".join(result))

func message_local_join(channel: String, result: bool):
	if result:
		_add_line("** Joining channel: " + channel)
	else:
		_add_line("** ! Could not join channel: " + channel)

func message_local_part(result: bool):
	if result:
		_add_line("** Parting current channel")
	else:
		_add_line("** ! Could not part current channel")
