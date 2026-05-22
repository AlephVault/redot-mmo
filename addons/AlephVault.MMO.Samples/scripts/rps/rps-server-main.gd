extends AlephVault__MMO__Server.Main


func _ready() -> void:
	super()
	server_started.connect(_server_started)
	server_stopped.connect(_server_stopped)
	client_entered.connect(_client_entered)
	client_left.connect(_client_left)
	print("Started the RPS MMO Server scene")


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("server_start"):
		print("launch() result:", launch(6777, 32, 0, 0, 0))
	if Input.is_action_just_pressed("server_stop"):
		print("stop() result:", stop())


func _server_started() -> void:
	print("RPS server started")


func _server_stopped() -> void:
	print("RPS server stopped")


func _client_entered(id: int) -> void:
	print("RPS client entered: %s" % id)


func _client_left(id: int) -> void:
	print("RPS client left: %s" % id)
