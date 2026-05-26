extends AlephVault__MMO__Client.Protocols.Protocol

var _world: Node
var _spawner: MultiplayerSpawner
var _default_scope_scenes: Array[PackedScene] = []
var _dynamic_scope_scenes: Array[PackedScene] = []

func _enter_tree() -> void:
	if not (get_parent() is AlephVault__MMO__Client.Protocols.Manager):
		return

	var world := _create_world()
	if world == null:
		return

	world.name = "World"
	add_child(world)
	_world = world

	_default_scope_scenes = _define_default_scopes()
	_dynamic_scope_scenes = _define_dynamic_scopes()

	var spawner := MultiplayerSpawner.new()
	spawner.name = "MultiplayerSpawner"
	_setup_spawner(spawner)
	spawner.set_multiplayer_authority(1)
	_add_scope_spawnable_scenes(spawner)
	add_child(spawner)
	_spawner = spawner

func _exit_tree() -> void:
	_default_scope_scenes.clear()
	_dynamic_scope_scenes.clear()

	if _world != null:
		remove_child(_world)
		_world.queue_free()
		_world = null

	if _spawner != null:
		remove_child(_spawner)
		_spawner.queue_free()
		_spawner = null

## Override this to instantiate the world node used by this spawning protocol.
func _create_world() -> Node:
	return null

## Override this to configure the MultiplayerSpawner used by this spawning protocol.
func _setup_spawner(s: MultiplayerSpawner) -> void:
	pass

## Override this to define static scope scenes created by the server.
func _define_default_scopes() -> Array[PackedScene]:
	return []

## Override this to define dynamic scope scene templates available on demand.
func _define_dynamic_scopes() -> Array[PackedScene]:
	return []

func _add_scope_spawnable_scenes(spawner: MultiplayerSpawner) -> void:
	var scenes: Array[PackedScene] = []
	scenes.append_array(_default_scope_scenes)
	scenes.append_array(_dynamic_scope_scenes)

	var paths := {}
	for scene in scenes:
		if scene == null or scene.resource_path == "" or paths.has(scene.resource_path):
			continue
		paths[scene.resource_path] = true
		spawner.add_spawnable_scene(scene.resource_path)
