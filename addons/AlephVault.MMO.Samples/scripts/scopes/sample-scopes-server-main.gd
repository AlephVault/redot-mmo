extends AlephVault__MMO__Server.Main

func _ready() -> void:
	super()
	server_started.connect(_server_started)
	server_stopped.connect(_server_stopped)
	client_entered.connect(_client_entered)
	client_left.connect(_client_left)
	scope_changed.connect(_scope_changed)
	print("[Scopes Sample:Server] Ready. F1 starts, F2 stops.")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("server_start"):
		print("[Scopes Sample:Server] launch() result:", launch(6777, 32, 0, 0, 0))
	if Input.is_action_just_pressed("server_stop"):
		print("[Scopes Sample:Server] stop() result:", stop())

func _server_started() -> void:
	print("[Scopes Sample:Server] Server started.")

func _server_stopped() -> void:
	print("[Scopes Sample:Server] Server stopped.")

func _client_entered(id: int) -> void:
	print("[Scopes Sample:Server] Client entered: %d" % id)

func _client_left(id: int) -> void:
	print("[Scopes Sample:Server] Client left: %d" % id)

func _scope_changed(connection_id: int, old_scope_id: int, new_scope_id: int) -> void:
	print(
		"[Scopes Sample:Server] Connection %d scope changed from %d to %d."
		% [connection_id, old_scope_id, new_scope_id]
	)
