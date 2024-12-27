extends AVMMOServerConnection

var _commands_class = preload("./sample-server-connection-commands.gd")
var _notifications_class = preload("./sample-server-connection-notifications.gd")

func _make_commands_node() -> AVMMOServerConnectionCommands:
	# Override this to instantiate the node serving the
	# commands that are issued to the server. Other than
	# that, the commands are implemented through RPC.
	return _commands_class.new()

func _make_notifications_node() -> AVMMOServerConnectionNotifications:
	# Override this to instantiate the node serving the
	# notifications to the client. Other than that, the
	# notifications are implemented through RPC.
	return _notifications_class.new()
