extends AlephVault__MMO__Client.Protocols.SpawningProtocol

const Commands = preload("./sample-scopes-client-commands.gd")
const ScopeScenes = [
	preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scope-red.tscn"),
	preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scope-green.tscn"),
	preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scope-blue.tscn"),
	preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scope-yellow.tscn"),
]

func _ready() -> void:
	active_scope_changed.connect(_active_scope_changed)

func _create_world() -> Node:
	var world := Control.new()
	world.size = Vector2(800, 600)
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	return world

func _setup_spawner(s: MultiplayerSpawner) -> void:
	s.spawn_path = get_node("World").get_path()
	s.spawn_function = _spawn_scope_from_index
	s.spawned.connect(func(node: Node):
		print("[Scopes Sample:Client] Spawner spawned %s." % node.name)
	)
	s.despawned.connect(func(node: Node):
		print("[Scopes Sample:Client] Spawner despawned %s." % node.name)
	)

func _define_default_scopes() -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	scenes.assign(ScopeScenes)
	return scenes

func _create_commands_node() -> AlephVault__MMO__Client.Protocols.Commands:
	return Commands.new()

func _setup_scope(scope: Node) -> void:
	var synchronizer := scope.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if synchronizer != null:
		var config := SceneReplicationConfig.new()
		config.add_property(NodePath("Label:text"))
		synchronizer.replication_config = config
		synchronizer.root_path = NodePath("..")
	print("[Scopes Sample:Client] Scope setup completed for %s." % scope.name)

func move_to_scope(scope_number: int) -> bool:
	return command("move_to_scope", [scope_number])

func _spawn_scope_from_index(data: Dictionary) -> Node:
	var scene_index := int(data.get("scene_index", -1))
	if scene_index < 0 or scene_index >= len(ScopeScenes):
		print("[Scopes Sample:Client] Invalid spawn scene index: %d" % scene_index)
		return null
	print("[Scopes Sample:Client] Custom spawn function for scene index %d." % scene_index)
	var scene := ScopeScenes[scene_index] as PackedScene
	return scene.instantiate()

func _active_scope_changed(current_scope: Node, scope: Node) -> void:
	var old_name := "<none>" if current_scope == null else current_scope.name
	var new_name := "<none>" if scope == null else scope.name
	print("[Scopes Sample:Client] Active replicated scope changed from %s to %s." % [old_name, new_name])
