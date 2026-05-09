extends RefCounted

var offset: int
var limit: int

func _init(offset_: int = 0, limit_: int = 0) -> void:
	offset = offset_
	limit = limit_

func query_string() -> String:
	return "offset=%s&limit=%s" % [offset, limit]
