extends Node

## Installs all registered protocols under the given connection.
func install(connection: AlephVault__MMO__Client.Connection) -> void:
	for child in get_children():
		var protocol = child as AlephVault__MMO__Client.Protocol
		if protocol == null:
			continue
		protocol.install(connection)
		var root = connection.get_node_or_null(str(protocol.name))
		if root == null:
			continue
		var commands = root.get_node_or_null("Commands")
		if commands != null:
			commands.set_multiplayer_authority(connection.id)
		var notifications = root.get_node_or_null("Notifications")
		if notifications != null:
			notifications.set_multiplayer_authority(1)
