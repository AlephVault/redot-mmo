extends Node

class_name AVMMOServerConnections

# The connections will be kept here.
var _connections: Dictionary = {}

## Adds a new connection object for the given
## connection id.
func add_client(id: int) -> AVMMOServerConnection:
	# Create the node.
	var node = AVMMOServerConnection.new()
	node.name = "Connection.%s" % id
	add_child(node, true)
	
	# Return the node.
	return node
