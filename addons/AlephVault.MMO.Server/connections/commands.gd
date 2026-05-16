extends Node

func _enter_tree() -> void:
	_connection = get_parent() as AlephVault__MMO__Server.Connection

var _connection: AlephVault__MMO__Server.Connection

## Gets the connection node.
var connection: AlephVault__MMO__Server.Connection:
	get:
		return _connection
	set(value):
		assert(false, "The connection node cannot be set this way")
