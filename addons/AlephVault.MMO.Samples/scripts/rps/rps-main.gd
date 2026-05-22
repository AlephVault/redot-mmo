extends Control


const CLIENT_SCENE = preload("res://addons/AlephVault.MMO.Samples/scenes/rps/rps-client.tscn")
const SERVER_SCENE = preload("res://addons/AlephVault.MMO.Samples/scenes/rps/rps-server.tscn")


func _ready() -> void:
	%ClientButton.pressed.connect(_choose_client)
	%ServerButton.pressed.connect(_choose_server)


func _choose_client() -> void:
	get_tree().change_scene_to_packed(CLIENT_SCENE)


func _choose_server() -> void:
	get_tree().change_scene_to_packed(SERVER_SCENE)
