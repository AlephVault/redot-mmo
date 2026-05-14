extends RefCounted

var id: Variant = null
var preview: Variant = null
var data: Variant = null

func _init(id_: Variant = null, preview_: Variant = null, data_: Variant = null) -> void:
	id = id_
	preview = preview_
	data = data_
