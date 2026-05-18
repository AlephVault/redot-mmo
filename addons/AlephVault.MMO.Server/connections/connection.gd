extends Node

## Triggered when a scope is changed for a connection.
## With (-1) for the scope, it means complete removal.
signal scope_changed(current_scope_id: int, id: int)

func _enter_tree() -> void:
	_connections = get_parent() as AlephVault__MMO__Server.Connections

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

var _connections: AlephVault__MMO__Server.Connections

## Gets the connections node.
var connections: AlephVault__MMO__Server.Connections:
	get:
		return _connections
	set(value):
		assert(false, "The connections node cannot be set this way")
