extends RefCounted

# Cursor used to page list resources.
var offset: int
var limit: int

## Creates a cursor with the given offset and limit.
func _init(offset_: int = 0, limit_: int = 0) -> void:
	offset = offset_
	limit = limit_

## Returns this cursor as the query string expected by list endpoints.
func query_string() -> String:
	return "offset=%s&limit=%s" % [offset, limit]
