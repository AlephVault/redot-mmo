extends Node

## Triggered when a scope is changed for a connection.
## With (-1) for the scope, it means complete removal.
signal scope_changed(current_scope_id: int, scope_id: int)

func _enter_tree() -> void:
	_connections = get_parent() as AlephVault__MMO__Client.Connections

## The is for this (client) connection.
var id: int = 0:
	set(value):
		if id != 0:
			assert(true, "The id for this connection is already set: %s" % id)
		else:
			id = value

# The current scope.
var _scope: int = AlephVault__MMO__Common.Scopes.make_fq_special_scope_id(AlephVault__MMO__Common.Scopes.SCOPE_LIMBO)

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
	($"../.." as AlephVault__MMO__Client.Main).scope_changed.emit(current_scope_id, id)

var _connections: AlephVault__MMO__Client.Connections

## Gets the connections node.
var connections: AlephVault__MMO__Client.Connections:
	get:
		return _connections
	set(value):
		assert(false, "The connections node cannot be set this way")
