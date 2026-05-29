extends Node

var client = preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scopes-client.tscn")
var server = preload("res://addons/AlephVault.MMO.Samples/scenes/scopes/sample-scopes-server.tscn")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("choose_client"):
		print("[Scopes Sample] Choosing client mode")
		get_tree().change_scene_to_packed(client)
	elif Input.is_action_just_pressed("choose_server"):
		print("[Scopes Sample] Choosing server mode")
		get_tree().change_scene_to_packed(server)
