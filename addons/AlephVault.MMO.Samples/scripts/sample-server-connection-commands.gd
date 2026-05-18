extends AlephVault__MMO__Server.ProtocolCommands

static var _allowed_channels: Dictionary = {
	"general": AlephVault__MMO__Common.Scopes.make_fq_default_scope_id(0),
	"gaming": AlephVault__MMO__Common.Scopes.make_fq_default_scope_id(1),
	"crypto": AlephVault__MMO__Common.Scopes.make_fq_default_scope_id(2),
	"hackers": AlephVault__MMO__Common.Scopes.make_fq_default_scope_id(3),
	"science": AlephVault__MMO__Common.Scopes.make_fq_default_scope_id(4),
}

func _enter_tree() -> void:
	print("Server protocol commands path:", get_path())

func _connection() -> AlephVault__MMO__Server.Connection:
	return $"../.." as AlephVault__MMO__Server.Connection

func _notify_owner(connection: AlephVault__MMO__Server.Connection, method: String, args: Array) -> void:
	connection.get_node("Chat/Notifications").rpc_id.callv([connection.id, method] + args)

var _channel: String = ""
var _current_nick: String = ""

## The current nick.
var current_nick: String:
	get:
		if _current_nick == "":
			return "Anonymous"
		else:
			return _current_nick
	set(value):
		_current_nick = value.strip_edges()

@rpc("authority", "call_remote", "reliable")
func list():
	print("Listing channels")
	var channels: Array[String] = []
	channels.assign(_allowed_channels.keys())
	_notify_owner(_connection(), "list_result", [channels])

@rpc("authority", "call_remote", "reliable")
func part():
	print("Leaving current channel")
	var connection = _connection()
	if _channel == "":
		_notify_owner(connection, "part_result", [false])
		return

	var connections: AlephVault__MMO__Server.Connections = connection.connections
	var id: int = connection.id
	var scope_id: int = connections.get_connection_scope(id)
	connections.set_connection_scope(id, AlephVault__MMO__Common.Scopes.make_fq_special_scope_id(AlephVault__MMO__Common.Scopes.SCOPE_LIMBO))
	
	var notify_part = func(node: AlephVault__MMO__Server.Connection):
		_notify_owner(node, "user_part", [id, current_nick])
	connections.scope_iterate(scope_id, notify_part)
	_channel = "";
	_notify_owner(connection, "part_result", [true])

@rpc("authority", "call_remote", "reliable")
func join(channel: String):
	print("Joining channel:", channel)
	var connection = _connection()
	if not _allowed_channels.has(channel):
		_notify_owner(connection, "join_result", [channel, false])
		return
	
	if channel == _channel:
		_notify_owner(connection, "join_result", [channel, true])
		return

	# Remove from current scope, and add to the
	# new scope.
	var connections: AlephVault__MMO__Server.Connections = connection.connections
	var id: int = connection.id
	var old_scope_id: int = connections.get_connection_scope(id)
	var new_scope_id: int = _allowed_channels[channel]
	connections.set_connection_scope(id, new_scope_id)

	# Tell the members of the previous scope.
	var notify_part = func(node: AlephVault__MMO__Server.Connection):
		_notify_owner(node, "user_part", [id, current_nick])
	connections.scope_iterate(old_scope_id, notify_part)
	
	# Tell the member of the new scope.
	var notify_join = func(node: AlephVault__MMO__Server.Connection):
		_notify_owner(node, "user_join", [id, current_nick])
	connections.scope_iterate(new_scope_id, notify_join)

	_channel = channel
	_notify_owner(connection, "join_result", [channel, true])

@rpc("authority", "call_remote", "reliable")
func send(message: String):
	print("Sending message:", message)
	if _channel == "":
		return
	
	var connection = _connection()
	var connections: AlephVault__MMO__Server.Connections = connection.connections
	var id: int = connection.id
	var scope_id: int = connections.get_connection_scope(id)

	var notify_sent = func(node: AlephVault__MMO__Server.Connection):
		_notify_owner(node, "user_sent", [id, current_nick, message])
	connections.scope_iterate(scope_id, notify_sent)

@rpc("authority", "call_remote", "reliable")
func nick(nickname: String):
	print("Setting nick to:", nickname)
	var connection = _connection()
	var old_nick = current_nick
	var new_nick = nickname.strip_edges()
	
	if nickname == "":
		_notify_owner(connection, "nick_result", [nickname, false])
		return
	current_nick = new_nick

	if _channel != "":
		var connections: AlephVault__MMO__Server.Connections = connection.connections
		var id: int = connection.id
		var scope_id: int = connections.get_connection_scope(id)

		var notify_nick = func(node: AlephVault__MMO__Server.Connection):
			_notify_owner(node, "user_nick", [id, old_nick, new_nick])
		connections.scope_iterate(scope_id, notify_nick)
	_notify_owner(connection, "nick_result", [nickname, true])
