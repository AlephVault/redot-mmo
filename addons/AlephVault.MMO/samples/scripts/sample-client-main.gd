extends AVMMOClient


const _connection_class = preload("./sample-client-connection.gd")
const _ui = preload("./sample-client-ui.gd")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	self.client_started.connect(_client_started)
	self.client_stopped.connect(_client_stopped)
	self.client_failed.connect(_client_failed)
	self.scope_changed.connect(_scope_changed)

	# Create the spawner (attach it with ownership).
	var client = _ui.new()
	client.name = "UI"
	add_child(client, true)
	client.owner = self
	_client = client
	
	print("Started the MMO Client scene")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("client_join"):
		print("join_server() result:", self.join_server("127.0.0.1", 6777))
	if Input.is_action_just_pressed("client_leave"):
		print("leave_server() result:", self.leave_server())


func connection_class() -> Script:
	return _connection_class


func _client_started():
	_client.message_connection_started()


func _client_stopped():
	_client.message_connection_closed()


func _client_failed():
	_client.message_connection_failed()


func _scope_changed(old_scope_id: int, new_scope_id: int):
	_client.message_scope_changed(new_scope_id)


var _client: _ui
