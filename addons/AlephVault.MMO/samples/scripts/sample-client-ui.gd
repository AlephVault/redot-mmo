extends Control


func _enter_tree():
	print("UI initialized")
	%SetNickname.connect("pressed", set_nickname)
	%SendCommand.connect("pressed", send_command)

func _exit_tree():
	%SetNickname.connect("pressed", set_nickname)
	%SendCommand.disconnect("pressed", send_command)

## Sets the nickname via command.
func set_nickname():
	var connection = ($".." as AVMMOClient).connections.get_connection_node()
	var nickname = $NewNickname.text.strip_edges()
	if nickname != "":
		$NewNickname.text = ""
		_message_local_nick(nickname, connection.commands.nick(nickname))

func _input(event):
	var node = get_viewport().gui_get_focus_owner()
	if Input.is_key_pressed(KEY_ENTER):
		if node == $NewNickname:
			set_nickname()
		elif node == $Command:
			send_command()

## Sends the current command.
func send_command():
	var command: String = $Command.text.strip_edges()
	if command == "":
		return
	$Command.text = ""
	var command_parts = command.split(" ", false, 1)
	var base_command: String = command_parts[0].to_lower()
	var argument = command_parts[1].strip_edges() if len(command_parts) > 1 else ""
	var connection = ($".." as AVMMOClient).connections.get_connection_node()
	if base_command == "/join":
		# Change the current channel.
		_message_local_join(argument, connection.commands.join(argument))
	elif base_command == "/part":
		# Leaves the current channel, if any.
		_message_local_part(connection.commands.part())
	elif base_command == "/nick":
		# Changes the nick.
		_message_local_nick(argument, connection.commands.nick(argument))
	elif base_command == "/list":
		# Lists the channels.
		_message_local_list(connection.commands.list())
	else:
		# Sends a message.
		connection.commands.send(argument)

func _add_line(line: String):
	var text: String = $Messages.text
	var new_text: String = line
	if text.strip_edges() != "":
		new_text = text + "\n" + line
	$Messages.text = new_text

func clear_messages():
	$Messages.text = ""

func message_connection_started():
	_add_line("## Connection started")

func message_connection_failed():
	_add_line("## Connection failed")

func message_connection_closed():
	_add_line("## Connection closed")

func message_scope_changed(id: int):
	_add_line("## [DEBUG] Scope changed: %d" % id)

func _message_local_nick(nick: String, result: bool):
	if result:
		_add_line("** Nick updated successfully: " + nick)
	else:
		_add_line("** ! Could not update nick: " + nick)

func _message_local_list(result: Array[String]):
	_add_line("** Available channels: " + ", ".join(result))

func _message_local_join(channel: String, result: bool):
	if result:
		_add_line("** Joining channel: " + channel)
	else:
		_add_line("** ! Could not join channel: " + channel)

func _message_local_part(result: bool):
	if result:
		_add_line("** Parting current channel")
	else:
		_add_line("** ! Could not part current channel")

func message_user_join(connection_id: int, nick: String):
	_add_line(">| %s (%d) joined the channel" % [nick, connection_id])

func message_user_part(connection_id: int, nick: String):
	_add_line(">| %s (%d) left the channel" % [nick, connection_id])

func message_user_sent(connection_id: int, nick: String, message: String):
	_add_line(">> %s (%d) :- %s" % [nick, connection_id, message])

func message_user_nick(connection_id: int, nick: String, new_nick: String):
	_add_line(">| %s (%d) is now known as: %s" % [nick, connection_id, new_nick])
