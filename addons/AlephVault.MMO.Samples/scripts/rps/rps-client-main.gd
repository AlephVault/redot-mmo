extends AlephVault__MMO__Client.Main


const UI_SCENE = preload("res://addons/AlephVault.MMO.Samples/scenes/rps/rps-ui.tscn")
const UI_SCRIPT = preload("./rps-ui.gd")

var _client_ui: UI_SCRIPT

var client_ui: UI_SCRIPT:
	get:
		return _client_ui
	set(value):
		assert(false, "The client's UI cannot be set this way")


func _ready() -> void:
	super()
	client_started.connect(_client_started)
	client_stopped.connect(_client_stopped)
	client_failed.connect(_client_failed)

	var instance = UI_SCENE.instantiate()
	instance.name = "UI"
	add_child(instance, true)
	instance.owner = self
	_client_ui = instance
	_client_ui.call_deferred("message_connection_closed")
	print("Started the RPS MMO Client scene")


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("client_join"):
		print("join_server() result:", join_server("127.0.0.1", 6777))
	if Input.is_action_just_pressed("client_leave"):
		print("leave_server() result:", leave_server())


func _client_started() -> void:
	_client_ui.message_connection_started()


func _client_stopped() -> void:
	_client_ui.message_connection_closed()


func _client_failed() -> void:
	_client_ui.message_connection_failed()
