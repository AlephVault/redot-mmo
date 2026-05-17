extends Node

## Implement this method to define the dependencies
## of the current protocol. Do it in terms of classes
## extending AlephVault__MMO__Client.Protocol.
static func _get_dependencies(): Array[Script]:
	return []

## The protocol classes this protocol depends on.
static var dependencies: Array[Script]:
	get:
		return _get_dependencies()
	set(value):
		assert(false, "The client's protocol dependencies cannot be set this way")
