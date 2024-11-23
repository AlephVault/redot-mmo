extends Node


var client = preload("res://addons/AlephVault.MMO/samples/scenes/sample-client.tscn")
var server = preload("res://addons/AlephVault.MMO/samples/scenes/sample-server.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("choose_client"):
		print("Choosing client")
		get_tree().change_scene_to_packed(client)
	elif Input.is_action_just_pressed("choose_server"):
		print("Choosing server")
		get_tree().change_scene_to_packed(server)
