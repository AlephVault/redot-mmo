extends Control

const ChatProtocol = preload("./sample-client-chat-protocol.gd")

func _enter_tree():
	print("UI initialized")
	%SetNickname.connect("pressed", set_nickname)
	%SendCommand.connect("pressed", send_command)

func _exit_tree():
	%SetNickname.disconnect("pressed", set_nickname)
	%SendCommand.disconnect("pressed", send_command)

func _chat_protocol() -> ChatProtocol:
	var main = $".." as AlephVault__MMO__Client.Main
	return main.protocols.get_node("Chat") as ChatProtocol

## Sets the nickname via command.
func set_nickname():
	var nickname = $NewNickname.text.strip_edges()
	if nickname != "":
		$NewNickname.text = ""
		_chat_protocol().nick(nickname)

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
	var chat = _chat_protocol()
	if base_command == "/join":
		# Change the current channel.
		chat.join(argument)
	elif base_command == "/part":
		# Leaves the current channel, if any.
		chat.part()
	elif base_command == "/nick":
		# Changes the nick.
		chat.nick(argument)
	elif base_command == "/list":
		# Lists the channels.
		chat.list()
	else:
		# Sends a message.
		chat.send(command)

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

func message_nick_result(nick: String, result: bool):
	if result:
		_add_line("** Nick updated successfully: " + nick)
	else:
		_add_line("** ! Could not update nick: " + nick)

func message_list_result(result: Array[String]):
	_add_line("** Available channels: " + ", ".join(result))

func message_join_result(channel: String, result: bool):
	if result:
		_add_line("** Joining channel: " + channel)
	else:
		_add_line("** ! Could not join channel: " + channel)

func message_part_result(result: bool):
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
