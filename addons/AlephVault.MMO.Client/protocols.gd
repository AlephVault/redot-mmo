extends Node

var _protocols_by_class: Dictionary = {}
var _protocols_by_class_dirty: bool = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_protocols_by_class_dirty = true

func _rebuild_protocols_by_class() -> void:
	_protocols_by_class.clear()
	for child in get_children():
		var protocol = child as AlephVault__MMO__Client.Protocol
		if protocol == null:
			continue
		var protocol_class = protocol.get_script() as Script
		if protocol_class != null:
			_protocols_by_class[protocol_class] = protocol
	_protocols_by_class_dirty = false

## Gets a protocol by its script class.
##
## Returns the protocol node registered under this Protocols node whose script
## is exactly protocol_class, or null if no such protocol was registered.
func get_protocol(protocol_class: Script) -> AlephVault__MMO__Client.Protocol:
	if _protocols_by_class_dirty:
		_rebuild_protocols_by_class()
	return _protocols_by_class.get(protocol_class, null) as AlephVault__MMO__Client.Protocol

## Installs all registered protocols under the given connection.
func install(connection: AlephVault__MMO__Client.Connection) -> void:
	print("[AlephVault.MMO:Client] Installing protocol nodes below " + connection.name)

	for child in get_children():
		print("[AlephVault.MMO:Client] Installing protocol by name: " + child.name)
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
