extends Node

## Triggered when a scope is changed for a connection.
## With (-1) for the scope, it means complete removal.
signal scope_changed(current_scope_id: int, id: int)

func _enter_tree() -> void:
	_connections = get_parent() as AlephVault__MMO.Server.Connections

## The is for this (server) connection.
var id: int = 0:
	set(value):
		if id != 0:
			assert(true, "The id for this connection is already set: %s" % id)
		else:
			id = value

## The current scope.
var scope: int:
	get:
		return get_parent().get_connection_scope(id)
	set(value):
		assert(false, "The scope cannot be set this way")

func _make_commands_node() -> AVMMOServerConnectionCommands:
	# Override this to instantiate the node serving the
	# commands that are issued to the server. Other than
	# that, the commands are implemented through RPC.
	return AVMMOServerConnectionCommands.new()

func _make_notifications_node() -> AVMMOServerConnectionNotifications:
	# Override this to instantiate the node serving the
	# notifications to the client. Other than that, the
	# notifications are implemented through RPC.
	return AVMMOServerConnectionNotifications.new()

var _commands: AVMMOServerConnectionCommands
var _notifications: AVMMOServerConnectionNotifications
var _connections: AlephVault__MMO.Server.Connections

## Gets the commands node from the connection.
var commands: AVMMOServerConnectionCommands:
	get:
		return _commands
	set(value):
		assert(false, "The commands node cannot be set this way")

## Gets the notifications node from the connection.
var notifications: AVMMOServerConnectionNotifications:
	get:
		return _notifications
	set(value):
		assert(false, "The notifications node cannot be set this way")

## Gets the connections node.
var connections: AlephVault__MMO.Server.Connections:
	get:
		return _connections
	set(value):
		assert(false, "The connections node cannot be set this way")

func init_authority():
	_commands = _make_commands_node()
	_commands.name = "Commands"
	add_child(_commands, true)
	_notifications = _make_notifications_node()
	_notifications.name = "Notifications"
	add_child(_notifications, true)
	_commands.set_multiplayer_authority(id)
	_notifications.set_multiplayer_authority(1)

## Sends an RPC from the notifications object to the
## owner of the connection.
func notify_owner(method: String, args: Array):
	notifications.rpc_id.callv([id, method] + args)
