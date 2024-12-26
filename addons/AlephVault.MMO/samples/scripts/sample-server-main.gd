extends AVMMOServer


const _connection_class = preload("./sample-server-connection.gd")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	self.server_started.connect(_server_started)
	self.server_stopped.connect(_server_stopped)
	self.client_entered.connect(_client_entered)
	self.client_left.connect(_client_left)
	print("Started the MMO Server scene")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("server_start"):
		print("launch() result:", self.launch(6777, 32, 0, 0, 0))
	if Input.is_action_just_pressed("server_stop"):
		print("stop() result:", self.stop())


func connection_class() -> Script:
	return _connection_class


func _server_started():
	print("Server started")


func _server_stopped():
	print("Server stopped")


func _client_left(id: int):
	print("Client left: %s" % id)


func _client_entered(id: int):
	print("Client entered: %s" % id)
