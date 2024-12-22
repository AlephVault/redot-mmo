extends Node

class_name AVMMOClientConnections

# The connections will be kept here. Actually, only
# one connection will belong here.
var _connections: Dictionary = {}

func _inherits_native_class(script: Script, native_class_name: String) -> bool:
	# If the script's top-level extends statement is "extends Node",
	# script.native_class == "Node"
	if script.native_class == native_class_name:
		return true
	var parent = script.get_base_script()
	if parent:
		return _inherits_native_class(parent, native_class_name)
	return false

## The class of connections to instantiate when a connection is
## established.
var connection_class: Script = AVMMOClientConnection:
	set(value):
		var inherits: bool = _inherits_native_class(value, "AVMMOClientConnection")
		assert(inherits, "The assigned connection class must inherit AVMMOClientConnection")
		if inherits:
			connection_class = value

## Adds a new connection object for the current
## connection id. It will be the only one here.
func add_client() -> AVMMOClientConnection:
	# Create the node.
	var node = connection_class.new()
	var id = multiplayer.get_unique_id()
	node.name = "Connection.%s" % id
	node.id = id
	add_child(node, true)
	
	# Return the node.
	return node

## Removes a client connection object for the
## given connection id.
func remove_client():
	# Remove the node. It will be only one single
	# child, and the id might not be THAT retrievable
	# because by this point the connection might be
	# terminated.
	var node = get_child(0)
	remove_child(node)
