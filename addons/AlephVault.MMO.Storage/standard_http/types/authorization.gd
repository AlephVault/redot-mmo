extends RefCounted

var scheme: String
var value: String

func _init(scheme_: String = "", value_: String = "") -> void:
	scheme = scheme_
	value = value_
