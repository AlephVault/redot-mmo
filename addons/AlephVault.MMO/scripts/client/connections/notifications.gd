extends Node

@rpc("authority", "call_remote", "reliable")
func set_scope(id: int):
	get_parent()._set_scope(id)
