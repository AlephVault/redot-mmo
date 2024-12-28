extends AVMMOServerConnectionCommands

static var _allowed_channels: Dictionary = {
	"general": AVMMOScopes.make_fq_default_scope_id(0),
	"gaming": AVMMOScopes.make_fq_default_scope_id(1),
	"crypto": AVMMOScopes.make_fq_default_scope_id(2),
	"hackers": AVMMOScopes.make_fq_default_scope_id(3),
	"science": AVMMOScopes.make_fq_default_scope_id(4),
}

func _enter_tree() -> void:
	super()
	print("Server connection commands path:", get_path())

var _channel: String = ""
var _current_nick: String = ""

## The current nick.
var current_nick: String:
	get:
		if _current_nick == "":
			return name
		else:
			return _current_nick
	set(value):
		_current_nick = value.strip_edges()

@rpc("authority", "call_remote", "reliable")
func list():
	print("Listing channels")
	connection.notify_owner("list_result", [_allowed_channels.keys()])

@rpc("authority", "call_remote", "reliable")
func part():
	print("Leaving current channel")
	if _channel == "":
		connection.notify_owner("part_result", [false])
		return

	var connections: AVMMOServerConnections = connection.connections
	var id: int = connection.id
	var scope_id: int = connections.get_connection_scope(id)
	connections.set_connection_scope(id, AVMMOScopes.make_fq_special_scope_id(AVMMOScopes.SCOPE_LIMBO))
	
	var notify_part = func(node: AVMMOServerConnection):
		node.notify_owner("user_part", [id, current_nick])
	connections.scope_iterate(scope_id, notify_part)
	_channel = "";
	connection.notify_owner("part_result", [true])

@rpc("authority", "call_remote", "reliable")
func join(channel: String):
	print("Joining channel:", channel)
	if not _allowed_channels.has(channel):
		connection.notify_owner("join_result", [channel, false])
		return
	
	if channel == _channel:
		connection.notify_owner("join_result", [channel, true])
		return

	# Remove from current scope, and add to the
	# new scope.
	var connections: AVMMOServerConnections = connection.connections
	var id: int = connection.id
	var old_scope_id: int = connections.get_connection_scope(id)
	var new_scope_id: int = _allowed_channels[channel]
	connections.set_connection_scope(id, new_scope_id)

	# Tell the members of the previous scope.
	var notify_part = func(node: AVMMOServerConnection):
		node.notify_owner("user_part", [id, current_nick])
	connections.scope_iterate(old_scope_id, notify_part)
	
	# Tell the member of the new scope.
	var notify_join = func(node: AVMMOServerConnection):
		node.notify_owner("user_join", [id, current_nick])
	connections.scope_iterate(new_scope_id, notify_join)

	_channel = channel
	connection.notify_owner("join_result", [channel, true])

@rpc("authority", "call_remote", "reliable")
func send(message: String):
	print("Sending message:", message)
	if _channel == "":
		return
	
	var connections: AVMMOServerConnections = connection.connections
	var id: int = connection.id
	var scope_id: int = connections.get_connection_scope(id)

	var notify_sent = func(node: AVMMOServerConnection):
		node.notify_owner("user_sent", [id, current_nick, message])
	connections.scope_iterate(scope_id, notify_sent)

@rpc("authority", "call_remote", "reliable")
func nick(nickname: String):
	print("Setting nick to:", nickname)
	var old_nick = current_nick
	var new_nick = nickname.strip_edges()
	
	if nickname == "":
		connection.notify_owner("nick_result", [nickname, false])
		return
	current_nick = new_nick

	if _channel != "":
		var connections: AVMMOServerConnections = connection.connections
		var id: int = connection.id
		var scope_id: int = connections.get_connection_scope(id)

		var notify_nick = func(node: AVMMOServerConnection):
			node.notify_owner("user_nick", [id, old_nick, new_nick])
		connections.scope_iterate(scope_id, notify_nick)
	connection.notify_owner("nick_result", [nickname, true])
