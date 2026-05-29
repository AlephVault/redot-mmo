extends AlephVault__MMO__Server.Protocols.Protocol

@export var scope_visibility_change_delay: float = 0.1

var _world: Node
var _spawner: MultiplayerSpawner
var _scope_spawn_function: Callable
var _default_scope_scenes: Array[PackedScene] = []
var _dynamic_scope_scenes: Array[PackedScene] = []
var _active_scopes: Dictionary = {}

func _enter_tree() -> void:
	var manager = get_parent() as AlephVault__MMO__Server.Protocols.Manager
	if manager == null:
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
	add_child(spawner)
	_spawner = spawner

	_connect_scope_changed(manager.get_parent() as AlephVault__MMO__Server.Main)

func server_started() -> void:
	_create_default_scope_instances()

func server_stopped() -> void:
	for scope in _active_scopes.values():
		if scope is Node:
			(scope as Node).queue_free()
	_active_scopes.clear()

func client_entered(id: int) -> void:
	var manager = get_parent() as AlephVault__MMO__Server.Protocols.Manager
	if manager == null:
		return
	var server = manager.get_parent() as AlephVault__MMO__Server.Main
	if server == null or server.connections == null:
		return
	_update_scope_visibility(server.connections.get_connection_scope(id), id)

func _exit_tree() -> void:
	var manager = get_parent() as AlephVault__MMO__Server.Protocols.Manager
	if manager != null:
		_disconnect_scope_changed(manager.get_parent() as AlephVault__MMO__Server.Main)

	_active_scopes.clear()
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

## Override this to define static scope scenes created with the world.
func _define_default_scopes() -> Array[PackedScene]:
	return []

## Override this to define dynamic scope scene templates available on demand.
func _define_dynamic_scopes() -> Array[PackedScene]:
	return []

## Creates a dynamic scope from a dynamic scope template index.
func create_dynamic_scope(dyn_scope_template_index: int, id: int) -> Node:
	if dyn_scope_template_index < 0 or dyn_scope_template_index >= len(_dynamic_scope_scenes):
		return null
	var fq_scope_id := AlephVault__MMO__Common.Scopes.make_fq_dynamic_scope_id(id)
	if fq_scope_id < 0 or _active_scopes.has(fq_scope_id):
		return null
	return _create_scope_instance(
		_dynamic_scope_scenes[dyn_scope_template_index],
		fq_scope_id,
		len(_default_scope_scenes) + dyn_scope_template_index,
		dyn_scope_template_index
	)

## Destroys an empty dynamic scope.
func destroy_dynamic_scope(id: int) -> void:
	var fq_scope_id := AlephVault__MMO__Common.Scopes.make_fq_dynamic_scope_id(id)
	if fq_scope_id < 0 or not _active_scopes.has(fq_scope_id) or _scope_has_connections(fq_scope_id):
		return
	var scope = _active_scopes[fq_scope_id] as Node
	if scope != null:
		scope.queue_free()

func _create_default_scope_instances() -> void:
	for index in range(len(_default_scope_scenes)):
		_create_scope_instance(
			_default_scope_scenes[index],
			AlephVault__MMO__Common.Scopes.make_fq_default_scope_id(index),
			index,
			-1
		)

func _create_scope_instance(scene: PackedScene, fq_scope_id: int, scene_index: int, dyn_scope_template_index: int) -> Node:
	if _world == null or _spawner == null or scene == null or fq_scope_id < 0 or scene_index < 0:
		return null
	if _active_scopes.has(fq_scope_id):
		return null
	var scope_name := _get_scope_node_name(fq_scope_id)
	if scope_name == "":
		return null
	var scope_type := fq_scope_id >> 30
	var scope_id := fq_scope_id & ((1 << 30) - 1)
	var scope := _spawner.spawn({
		"scene_index": scene_index,
		"fq_scope_id": fq_scope_id,
		"scope_type": scope_type,
		"scope_id": scope_id,
		"dynamic_scope_template_index": dyn_scope_template_index,
		"name": scope_name,
	}) as Node
	if scope == null:
		return null
	_active_scopes[fq_scope_id] = scope
	_connect_scope_destroying(scope, fq_scope_id)
	return scope

func _get_scope_node_name(fq_scope_id: int) -> String:
	var scope_type := fq_scope_id >> 30
	var scope_id := fq_scope_id & ((1 << 30) - 1)
	match scope_type:
		AlephVault__MMO__Common.Scopes.ScopeType.DEFAULT:
			return "Scope%d" % scope_id
		AlephVault__MMO__Common.Scopes.ScopeType.DYNAMIC:
			return "DynScope%d" % scope_id
		_:
			return ""

func _get_scope_synchronizer(scope: Node) -> MultiplayerSynchronizer:
	if scope == null:
		return null
	return scope.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer

func _spawn_scope(data: Variant) -> Node:
	if not (data is Dictionary):
		return null
	var spawn_data := data as Dictionary
	var fq_scope_id := int(spawn_data.get("fq_scope_id", -1))
	var scope_name := String(spawn_data.get("name", ""))
	if fq_scope_id < 0 or scope_name == "":
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

	var synchronizer := _get_scope_synchronizer(scope)
	if synchronizer == null:
		scope.free()
		return null
	synchronizer.set_multiplayer_authority(1)
	_setup_scope_synchronizer(synchronizer, fq_scope_id)
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

## Override this to configure a scope root after it is instantiated.
func _setup_scope(scope: Node) -> void:
	pass

func _setup_scope_synchronizer(synchronizer: MultiplayerSynchronizer, fq_scope_id: int) -> void:
	synchronizer.public_visibility = false
	synchronizer.root_path = NodePath("..")
	synchronizer.visibility_update_mode = MultiplayerSynchronizer.VISIBILITY_PROCESS_NONE
	synchronizer.add_visibility_filter(_is_scope_visible_for_connection.bind(fq_scope_id))

func _is_scope_visible_for_connection(connection_id: int, fq_scope_id: int) -> bool:
	var manager = get_parent() as AlephVault__MMO__Server.Protocols.Manager
	if manager == null:
		return false
	var server = manager.get_parent() as AlephVault__MMO__Server.Main
	if server == null or server.connections == null:
		return false
	return (
		server.connections.has_connection(connection_id)
		and server.connections.get_connection_scope(connection_id) == fq_scope_id
	)

func _connect_scope_changed(server: AlephVault__MMO__Server.Main) -> void:
	if server != null and not server.scope_changed.is_connected(_on_scope_changed):
		server.scope_changed.connect(_on_scope_changed)

func _disconnect_scope_changed(server: AlephVault__MMO__Server.Main) -> void:
	if server != null and server.scope_changed.is_connected(_on_scope_changed):
		server.scope_changed.disconnect(_on_scope_changed)

func _on_scope_changed(connection_id: int, current_scope_id: int, scope_id: int) -> void:
	if current_scope_id == scope_id:
		return

	_update_scope_visibility(current_scope_id, connection_id)
	if scope_visibility_change_delay > 0:
		await get_tree().create_timer(scope_visibility_change_delay).timeout
	_update_scope_visibility(scope_id, connection_id)

func _update_scope_visibility(fq_scope_id: int, connection_id: int) -> void:
	if fq_scope_id < 0 or not _active_scopes.has(fq_scope_id):
		return
	var synchronizer := _get_scope_synchronizer(_active_scopes[fq_scope_id])
	if synchronizer != null:
		synchronizer.set_visibility_for(connection_id, _is_scope_visible_for_connection(connection_id, fq_scope_id))

func _connect_scope_destroying(scope: Node, fq_scope_id: int) -> void:
	if scope != null:
		scope.tree_exiting.connect(_on_scope_tree_exiting.bind(scope, fq_scope_id))

func _on_scope_tree_exiting(scope: Node, fq_scope_id: int) -> void:
	if scope != null and scope.is_queued_for_deletion() and _active_scopes.get(fq_scope_id) == scope:
		_active_scopes.erase(fq_scope_id)

func _scope_has_connections(fq_scope_id: int) -> bool:
	var manager = get_parent() as AlephVault__MMO__Server.Protocols.Manager
	if manager == null:
		return false
	var server = manager.get_parent() as AlephVault__MMO__Server.Main
	if server == null or server.connections == null:
		return false
	return len(server.connections.get_connections_in_scope(fq_scope_id)) > 0
