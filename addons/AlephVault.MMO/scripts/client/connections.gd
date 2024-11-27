extends Node

class_name AVMMOClientConnections

# The connections will be kept here. Actually, only
# one connection will belong here.
var _connections: Dictionary = {}

## Adds a new connection object for the current
## connection id. It will be the only one here.
func add_client() -> AVMMOClientConnection:
	# Create the node.
	var node = AVMMOClientConnection.new()
	var id = multiplayer.get_unique_id()
	node.name = "Connection.%s" % id
	add_child(node, true)
	
	# Return the node.
	return node
