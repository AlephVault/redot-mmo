extends AlephVault__MMO__Client.Main

const ScopesProtocol = preload("./sample-scopes-client-protocol.gd")

func _ready() -> void:
	super()
	client_started.connect(_client_started)
	client_stopped.connect(_client_stopped)
	client_failed.connect(_client_failed)
	scope_changed.connect(_scope_changed)
	print("[Scopes Sample:Client] Ready. F1 connects, F2 disconnects, keys 1-4 request scopes.")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("client_join"):
		print("[Scopes Sample:Client] join_server() result:", join_server("127.0.0.1", 6777))
	if Input.is_action_just_pressed("client_leave"):
		print("[Scopes Sample:Client] leave_server() result:", leave_server())

func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_request_scope(1)
		KEY_2:
			_request_scope(2)
		KEY_3:
			_request_scope(3)
		KEY_4:
			_request_scope(4)

func _request_scope(scope_number: int) -> void:
	var protocol := protocols.get_protocol(ScopesProtocol) as AlephVault__MMO__Client.Protocols.Protocol
	if protocol == null:
		print("[Scopes Sample:Client] Cannot request scope %d: protocol is not installed." % scope_number)
		return
	var sent := protocol.call("move_to_scope", scope_number) as bool
	print("[Scopes Sample:Client] Request scope %d sent: %s" % [scope_number, sent])

func _client_started() -> void:
	print("[Scopes Sample:Client] Client started.")

func _client_stopped() -> void:
	print("[Scopes Sample:Client] Client stopped.")

func _client_failed() -> void:
	print("[Scopes Sample:Client] Client failed.")

func _scope_changed(old_scope_id: int, new_scope_id: int) -> void:
	print("[Scopes Sample:Client] Scope changed from %d to %d." % [old_scope_id, new_scope_id])
