extends AlephVault__MMO__Server.Protocols.SpawningProtocol

const Commands = preload("./sample-scopes-server-commands.gd")
const ScopeScenes = [
	preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scope-red.tscn"),
	preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scope-green.tscn"),
	preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scope-blue.tscn"),
	preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scope-yellow.tscn"),
]

var _label_update_time: float = 0.0
var _label_update_index: int = 0

func _create_world() -> Node:
	var world := Control.new()
	world.size = Vector2(800, 600)
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	return world

func _setup_spawner(s: MultiplayerSpawner) -> void:
	s.spawn_path = get_node("World").get_path()
	s.spawn_function = _spawn_scope_from_index
	s.spawned.connect(func(node: Node):
		print("[Scopes Sample:Server] Spawner spawned %s." % node.name)
	)
	s.despawned.connect(func(node: Node):
		print("[Scopes Sample:Server] Spawner despawned %s." % node.name)
	)

func _define_default_scopes() -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	scenes.assign(ScopeScenes)
	return scenes

func _create_commands_node() -> AlephVault__MMO__Server.Protocols.Commands:
	return Commands.new()

func _setup_scope(scope: Node) -> void:
	var synchronizer := scope.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if synchronizer != null:
		var config := SceneReplicationConfig.new()
		config.add_property(NodePath("Label:text"))
		synchronizer.replication_config = config
		synchronizer.root_path = NodePath("..")
	print("[Scopes Sample:Server] Scope setup completed for %s." % scope.name)

func _process(delta: float) -> void:
	_label_update_time += delta
	if _label_update_time < 1.0:
		return
	_label_update_time = 0.0
	_label_update_index += 1
	for fq_scope_id in _active_scopes.keys():
		var scope := _active_scopes[fq_scope_id] as Node
		if scope == null:
			continue
		var label := scope.get_node_or_null("Label") as Label
		if label == null:
			continue
		var scope_id := int(fq_scope_id) & ((1 << 30) - 1)
		label.text = "Scope %d | server tick %d" % [scope_id + 1, _label_update_index]

func _spawn_scope_from_index(data: Dictionary) -> Node:
	var scene_index := int(data.get("scene_index", -1))
	if scene_index < 0 or scene_index >= len(ScopeScenes):
		print("[Scopes Sample:Server] Invalid spawn scene index: %d" % scene_index)
		return null
	print("[Scopes Sample:Server] Custom spawn function for scene index %d." % scene_index)
	var scene := ScopeScenes[scene_index] as PackedScene
	return scene.instantiate()

func _is_scope_visible_for_connection(connection_id: int, fq_scope_id: int) -> bool:
	var visible := super._is_scope_visible_for_connection(connection_id, fq_scope_id)
	print(
		"[Scopes Sample:Server] Scope %d visibility for connection %d: %s."
		% [fq_scope_id, connection_id, visible]
	)
	return visible
