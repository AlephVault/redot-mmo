extends RefCounted

const Nothing = preload("./nothing.gd")

static func serialize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME:
			return value
		TYPE_ARRAY:
			var result: Array = []
			for item in value:
				result.append(serialize(item))
			return result
		TYPE_DICTIONARY:
			var result := {}
			for key in value:
				result[key] = serialize(value[key])
			return result
		TYPE_OBJECT:
			return _serialize_object(value)
		_:
			return value

static func deserialize(data: Variant, target_class: Script) -> Dictionary:
	if target_class == null:
		return {"ok": false, "value": null}
	if target_class == Nothing:
		return {"ok": true, "value": target_class.new()}
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "value": null}
	return _deserialize_object(data, target_class)

static func _serialize_object(value: Object) -> Dictionary:
	var result := {}
	for property in value.get_property_list():
		var property_name = str(property.get("name", ""))
		var usage = int(property.get("usage", 0))
		if property_name == "script" or (usage & PROPERTY_USAGE_STORAGE) == 0:
			continue
		result[property_name] = serialize(value.get(property_name))
	return result

static func _deserialize_object(data: Dictionary, target_class: Script) -> Dictionary:
	var instance = target_class.new()
	var writable_properties := {}
	for property in instance.get_property_list():
		var property_name = str(property.get("name", ""))
		var usage = int(property.get("usage", 0))
		if property_name == "script" or (usage & PROPERTY_USAGE_STORAGE) == 0:
			continue
		writable_properties[property_name] = property

	for key in data:
		var property_name = str(key)
		if not writable_properties.has(property_name):
			continue
		var converted = _deserialize_value(
			data[key], writable_properties[property_name], instance.get(property_name)
		)
		if not converted.ok:
			return {"ok": false, "value": null}
		instance.set(property_name, converted.value)

	return {"ok": true, "value": instance}

static func _deserialize_value(data: Variant, property: Dictionary, current_value: Variant) -> Dictionary:
	var expected_type = int(property.get("type", TYPE_NIL))
	if data == null:
		if expected_type == TYPE_OBJECT or expected_type == TYPE_NIL:
			return _ok(null)
		return _failed()

	match expected_type:
		TYPE_NIL:
			return _ok(data)
		TYPE_BOOL:
			if typeof(data) == TYPE_BOOL:
				return _ok(data)
		TYPE_INT:
			if typeof(data) == TYPE_INT or typeof(data) == TYPE_FLOAT:
				return _ok(int(data))
		TYPE_FLOAT:
			if typeof(data) == TYPE_INT or typeof(data) == TYPE_FLOAT:
				return _ok(float(data))
		TYPE_STRING:
			if typeof(data) == TYPE_STRING:
				return _ok(data)
		TYPE_STRING_NAME:
			if typeof(data) == TYPE_STRING or typeof(data) == TYPE_STRING_NAME:
				return _ok(StringName(data))
		TYPE_DICTIONARY:
			if typeof(data) == TYPE_DICTIONARY:
				return _ok(data)
		TYPE_ARRAY:
			if typeof(data) == TYPE_ARRAY:
				return _deserialize_array(data, property)
		TYPE_OBJECT:
			return _deserialize_object_value(data, property, current_value)
		_:
			if typeof(data) == expected_type:
				return _ok(data)
	return _failed()

static func _deserialize_array(data: Variant, property: Dictionary) -> Dictionary:
	if typeof(data) != TYPE_ARRAY:
		return _failed()

	var element_script = _script_from_hint_string(str(property.get("hint_string", "")))
	var result: Array = []
	for item in data:
		if element_script != null:
			var deserialized = deserialize(item, element_script)
			if not deserialized.ok:
				return _failed()
			result.append(deserialized.value)
		else:
			result.append(item)
	return _ok(result)

static func _deserialize_object_value(data: Variant, property: Dictionary, current_value: Variant) -> Dictionary:
	var script = _script_from_property(property)
	if script == null and current_value is Object:
		script = current_value.get_script() as Script
	if script == null:
		return _failed()
	return deserialize(data, script)

static func _script_from_property(property: Dictionary) -> Script:
	var class_name = str(property.get("class_name", ""))
	var script = _script_from_class_name(class_name)
	if script != null:
		return script
	return _script_from_hint_string(str(property.get("hint_string", "")))

static func _script_from_hint_string(hint_string: String) -> Script:
	var path = _script_path_from_hint_string(hint_string)
	if path != "":
		var loaded = load(path)
		if loaded is Script:
			return loaded

	for global_class in ProjectSettings.get_global_class_list():
		var class_name = str(global_class.get("class", ""))
		if class_name != "" and hint_string.find(class_name) != -1:
			return _script_from_class_name(class_name)
	return null

static func _script_from_class_name(class_name: String) -> Script:
	if class_name == "":
		return null
	for global_class in ProjectSettings.get_global_class_list():
		if str(global_class.get("class", "")) == class_name:
			var loaded = load(str(global_class.get("path", "")))
			if loaded is Script:
				return loaded
	return null

static func _script_path_from_hint_string(hint_string: String) -> String:
	var start = hint_string.find("res://")
	if start == -1:
		return ""
	var end = hint_string.find(".gd", start)
	if end == -1:
		return ""
	return hint_string.substr(start, end - start + 3)

static func _ok(value: Variant) -> Dictionary:
	return {"ok": true, "value": value}

static func _failed() -> Dictionary:
	return {"ok": false, "value": null}
