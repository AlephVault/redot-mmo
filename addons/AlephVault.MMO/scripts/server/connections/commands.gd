extends Node

class_name AVMMOServerConnectionCommands

func _enter_tree() -> void:
	_connection = get_parent() as AVMMOServerConnection

var _connection: AVMMOServerConnection

## Gets the connection node.
var connection: AVMMOServerConnection:
	get:
		return _connection
	set(value):
		assert(false, "The connection node cannot be set this way")
