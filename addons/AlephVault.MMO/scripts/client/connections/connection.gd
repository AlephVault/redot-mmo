extends Node

class_name AVMMOClientConnection

## The is for this (client) connection.
var id: int = 0:
	set(value):
		if id != 0:
			assert(true, "The id for this connection is already set: %s" % id)
		else:
			id = value

func _make_commands_node():
	# Override this to instantiate the node serving the
	# commands that are issued to the server. Other than
	# that, the commands are implemented through RPC.
	return Node.new()

func _make_notifications_mode():
	# Override this to instantiate the node serving the
	# notifications to the client. Other than that, the
	# notifications are implemented through RPC.
	return Node.new()

var _commands: Node
var _notifications: Node

func init_authority():
	_commands = _make_commands_node()
	add_child(_commands)
	_notifications = _make_notifications_mode()
	add_child(_notifications)
	_commands.set_multiplayer_authority(id)
	_notifications.set_multiplayer_authority(1)
