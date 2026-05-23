extends AlephVault__MMO__Server.Protocols.Protocol

var _world: Node
var _spawner: MultiplayerSpawner

func _enter_tree() -> void:
	if not (get_parent() is AlephVault__MMO__Server.Protocols.Manager):
		return

	var world := _create_world()
	if world == null:
		return

	world.name = "World"
	add_child(world)
	_world = world

	var spawner := MultiplayerSpawner.new()
	spawner.name = "MultiplayerSpawner"
	_setup_spawner(spawner)
	add_child(spawner)
	_spawner = spawner

func _exit_tree() -> void:
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
