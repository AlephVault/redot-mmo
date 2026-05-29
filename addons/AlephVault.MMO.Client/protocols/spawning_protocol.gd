extends AlephVault__MMO__Client.Protocols.Protocol

## Triggered when the active replicated scope changes.
signal active_scope_changed(current_scope: Node, scope: Node)

var _world: Node
var _spawner: MultiplayerSpawner
var _scope_spawn_function: Callable
var _default_scope_scenes: Array[PackedScene] = []
var _dynamic_scope_scenes: Array[PackedScene] = []
var _active_scope: Node

## The currently replicated scope root node.
var active_scope: Node:
	get:
		return _active_scope
	set(value):
		assert(false, "The active scope cannot be set this way")

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
	_scope_spawn_function = spawner.spawn_function
	spawner.spawn_function = _spawn_scope
	spawner.set_multiplayer_authority(1)
	spawner.spawned.connect(_on_scope_spawned)
	spawner.despawned.connect(_on_scope_despawned)
	add_child(spawner)
	_spawner = spawner

func _exit_tree() -> void:
	_set_active_scope(null)
	_scope_spawn_function = Callable()
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

## Override this to configure a replicated scope root after it is spawned.
func _setup_scope(scope: Node) -> void:
	pass

func _set_active_scope(scope: Node) -> void:
	if _active_scope == scope:
		return
	var current_scope := _active_scope
	_active_scope = scope
	active_scope_changed.emit(current_scope, _active_scope)

func _spawn_scope(data: Variant) -> Node:
	if not (data is Dictionary):
		return null
	var spawn_data := data as Dictionary
	var scope_name := String(spawn_data.get("name", ""))
	if scope_name == "":
		return null

	var scope: Node
	if _scope_spawn_function.is_valid():
		scope = _scope_spawn_function.call(spawn_data) as Node
	else:
		scope = _instantiate_scope_from_spawn_data(spawn_data)
	if scope == null or scope.is_inside_tree():
		return null

	scope.set_multiplayer_authority(1)
	scope.name = scope_name
	_setup_scope(scope)
	var synchronizer := scope.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if synchronizer != null:
		synchronizer.set_multiplayer_authority(1)
	return scope

func _instantiate_scope_from_spawn_data(spawn_data: Dictionary) -> Node:
	var scene_index := int(spawn_data.get("scene_index", -1))
	var scene := _get_scope_scene(scene_index)
	if scene == null:
		return null
	return scene.instantiate()

func _get_scope_scene(scene_index: int) -> PackedScene:
	if scene_index < 0:
		return null
	if scene_index < len(_default_scope_scenes):
		return _default_scope_scenes[scene_index]
	scene_index -= len(_default_scope_scenes)
	if scene_index < len(_dynamic_scope_scenes):
		return _dynamic_scope_scenes[scene_index]
	return null

func _on_scope_spawned(scope: Node) -> void:
	_set_active_scope(scope)

func _on_scope_despawned(scope: Node) -> void:
	if _active_scope == scope:
		_set_active_scope(null)
