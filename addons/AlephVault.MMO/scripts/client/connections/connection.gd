extends Node

class_name AVMMOClientConnection

## Triggered when a scope is changed for a connection.
## With (-1) for the scope, it means complete removal.
signal scope_changed(current_scope_id: int, scope_id: int)

func _enter_tree() -> void:
	_connections = get_parent() as AVMMOClientConnections

## The is for this (client) connection.
var id: int = 0:
	set(value):
		if id != 0:
			assert(true, "The id for this connection is already set: %s" % id)
		else:
			id = value

# The current scope.
var _scope: int = AVMMOScopes.make_fq_special_scope_id(AVMMOScopes.SCOPE_LIMBO)

## The current scope.
var scope: int:
	get:
		return _scope
	set(value):
		assert(false, "The scope cannot be set this way")

func _set_scope(id: int):
	var current_scope_id: int = _scope
	_scope = id
	scope_changed.emit(current_scope_id, id)
	($"../.." as AVMMOClient).scope_changed.emit(current_scope_id, id)

func _make_commands_node() -> AVMMOClientConnectionCommands:
	# Override this to instantiate the node serving the
	# commands that are issued to the server. Other than
	# that, the commands are implemented through RPC.
	return AVMMOClientConnectionCommands.new()

func _make_notifications_node() -> AVMMOClientConnectionNotifications:
	# Override this to instantiate the node serving the
	# notifications to the client. Other than that, the
	# notifications are implemented through RPC.
	return AVMMOClientConnectionNotifications.new()

var _commands: AVMMOClientConnectionCommands
var _notifications: AVMMOClientConnectionNotifications
var _connections: AVMMOClientConnections

## Gets the commands node from the connection.
var commands: AVMMOClientConnectionCommands:
	get:
		return _commands
	set(value):
		assert(false, "The commands node cannot be set this way")

## Gets the notifications node from the connection.
var notifications: AVMMOClientConnectionNotifications:
	get:
		return _notifications
	set(value):
		assert(false, "The notifications node cannot be set this way")

## Gets the connections node.
var connections: AVMMOClientConnections:
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
