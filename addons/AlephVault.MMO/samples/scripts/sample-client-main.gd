extends AVMMOClient


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.client_started.connect(_client_started)
	self.client_stopped.connect(_client_stopped)
	self.client_failed.connect(_client_failed)
	print("Started the MMO Client scene")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("client_join"):
		print("join_server() result:", self.join_server("127.0.0.1", 6777))
	if Input.is_action_just_pressed("client_leave"):
		print("leave_server() result:", self.leave_server())


func _client_started():
	print("Client started")


func _client_stopped():
	print("Client stopped")


func _client_failed():
	print("Client failed")
