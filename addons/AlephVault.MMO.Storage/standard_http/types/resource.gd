extends RefCounted

const Result = AlephVault__MMO__Storage.Types.Result
const ResultCode = AlephVault__MMO__Storage.Types.ResultCode
const Authorization = AlephVault__MMO__Storage.StandardHttp.Authorization

# Base class for standard HTTP storage resource handles.
#
# This class stores the resource name, base endpoint, and authorization shared
# by simple and list resources. It also contains the recursive JSON-to-script
# mapper used by typed methods such as read_as() and operation_to().
var name: String
var base_endpoint: String
var authorization: Authorization

## Creates a resource handle.
##
## [base_endpoint_] is normalized by trimming its trailing slash.
func _init(
	name_: String = "",
	base_endpoint_: String = "",
	authorization_: Authorization = null
) -> void:
	name = name_
	base_endpoint = base_endpoint_.trim_suffix("/")
	authorization = authorization_

## Returns [success_result] when the engine response is OK, otherwise converts
## the engine response into a failed [Result].
func _wrap_response(
	response: Dictionary, success_result: Result
) -> Result:
	if response.ok:
		return success_result
	return Result.failed(response.code, response.validation_errors, response.request_error_code)

## Converts an engine response containing a JSON object into a typed [Result].
##
## [response_class] must be a script that can be instantiated with new().
## Matching JSON keys are recursively copied into stored properties on the
## new instance. Any nested conversion failure fails the whole result.
func _wrap_deserialized_response(response: Dictionary, response_class: Script) -> Result:
	if not response.ok:
		return Result.failed(response.code, response.validation_errors, response.request_error_code)
	var deserialized = _deserialize_object(response.data, response_class)
	if not deserialized.ok:
		return Result.failed(ResultCode.FormatError)
	return Result.ok(deserialized.element)

## Converts an engine response containing a JSON array into typed instances.
##
## Each array item must be a JSON object that can be mapped into [element_class].
func _wrap_deserialized_array_response(response: Dictionary, element_class: Script) -> Result:
	if not response.ok:
		return Result.failed(response.code, response.validation_errors, response.request_error_code)
	if typeof(response.data) != TYPE_ARRAY:
		return Result.failed(ResultCode.FormatError)

	var elements: Array = []
	for item in response.data:
		var deserialized = _deserialize_object(item, element_class)
		if not deserialized.ok:
			return Result.failed(ResultCode.FormatError)
		elements.append(deserialized.element)
	return Result.ok_many(elements)

## Returns the endpoint for this resource.
func _endpoint() -> String:
	return "%s/%s" % [base_endpoint, name]

## Returns the endpoint for a custom resource method.
func _method_endpoint(method: String) -> String:
	return "%s/~%s" % [_endpoint(), method]

## Creates an instance of [response_class] from a JSON object.
##
## Matching JSON keys are assigned recursively. Object properties use their
## declared script type when it can be detected from Godot's property metadata.
## Array properties also deserialize each item when a typed element script or
## primitive element type can be detected.
func _deserialize_object(data: Variant, response_class: Script) -> Dictionary:
	if response_class == null or typeof(data) != TYPE_DICTIONARY:
		return {"ok": false}

	var instance = response_class.new()
	var writable_properties := {}
	for property in instance.get_property_list():
		var property_name = str(property.get("name", ""))
		var usage = int(property.get("usage", 0))
		if property_name == "script" or (usage & PROPERTY_USAGE_STORAGE) == 0:
			continue
		writable_properties[property_name] = property

	for key in data:
		var property_name = str(key)
		if writable_properties.has(property_name):
			var converted = _deserialize_value(
				data[key], writable_properties[property_name], instance.get(property_name)
			)
			if not converted.ok:
				return {"ok": false}
			instance.set(property_name, converted.value)

	return {
		"ok": true,
		"element": instance,
	}

## Recursively converts one JSON value for a target property.
func _deserialize_value(data: Variant, property: Dictionary, current_value: Variant) -> Dictionary:
	var expected_type = int(property.get("type", TYPE_NIL))
	if data == null:
		if expected_type == TYPE_OBJECT or expected_type == TYPE_NIL:
			return _deserialized_value(null)
		return {"ok": false}

	match expected_type:
		TYPE_NIL:
			return _deserialized_value(data)
		TYPE_BOOL:
			if typeof(data) == TYPE_BOOL:
				return _deserialized_value(data)
		TYPE_INT:
			if typeof(data) == TYPE_INT or typeof(data) == TYPE_FLOAT:
				return _deserialized_value(int(data))
		TYPE_FLOAT:
			if typeof(data) == TYPE_INT or typeof(data) == TYPE_FLOAT:
				return _deserialized_value(float(data))
		TYPE_STRING:
			if typeof(data) == TYPE_STRING:
				return _deserialized_value(data)
		TYPE_STRING_NAME:
			if typeof(data) == TYPE_STRING or typeof(data) == TYPE_STRING_NAME:
				return _deserialized_value(StringName(data))
		TYPE_DICTIONARY:
			if typeof(data) == TYPE_DICTIONARY:
				return _deserialized_value(data)
		TYPE_ARRAY:
			return _deserialize_array(data, property)
		TYPE_OBJECT:
			return _deserialize_object_value(data, property, current_value)
		TYPE_PACKED_BYTE_ARRAY:
			return _deserialize_packed_array(data, TYPE_INT, TYPE_PACKED_BYTE_ARRAY)
		TYPE_PACKED_INT32_ARRAY:
			return _deserialize_packed_array(data, TYPE_INT, TYPE_PACKED_INT32_ARRAY)
		TYPE_PACKED_INT64_ARRAY:
			return _deserialize_packed_array(data, TYPE_INT, TYPE_PACKED_INT64_ARRAY)
		TYPE_PACKED_FLOAT32_ARRAY:
			return _deserialize_packed_array(data, TYPE_FLOAT, TYPE_PACKED_FLOAT32_ARRAY)
		TYPE_PACKED_FLOAT64_ARRAY:
			return _deserialize_packed_array(data, TYPE_FLOAT, TYPE_PACKED_FLOAT64_ARRAY)
		TYPE_PACKED_STRING_ARRAY:
			return _deserialize_packed_array(data, TYPE_STRING, TYPE_PACKED_STRING_ARRAY)
		_:
			if typeof(data) == expected_type:
				return _deserialized_value(data)
	return {"ok": false}

## Recursively converts a JSON object into a declared object property type.
func _deserialize_object_value(data: Variant, property: Dictionary, current_value: Variant) -> Dictionary:
	var script = _script_from_property(property)
	if script == null and current_value is Object:
		script = current_value.get_script() as Script
	if script == null:
		return {"ok": false}

	var deserialized = _deserialize_object(data, script)
	if not deserialized.ok:
		return {"ok": false}
	return _deserialized_value(deserialized.element)

## Recursively converts a JSON array, including typed script or primitive items.
func _deserialize_array(data: Variant, property: Dictionary) -> Dictionary:
	if typeof(data) != TYPE_ARRAY:
		return {"ok": false}

	var element_script = _array_element_script(property)
	var element_type = _array_element_type(property)
	var result: Array = []
	for item in data:
		if element_script != null:
			var deserialized = _deserialize_object(item, element_script)
			if not deserialized.ok:
				return {"ok": false}
			result.append(deserialized.element)
		elif element_type != TYPE_NIL:
			var converted = _deserialize_plain_value(item, element_type)
			if not converted.ok:
				return {"ok": false}
			result.append(converted.value)
		else:
			result.append(item)
	return _deserialized_value(result)

## Converts a JSON array into a Godot packed array with primitive validation.
func _deserialize_packed_array(data: Variant, element_type: int, packed_array_type: int) -> Dictionary:
	if typeof(data) != TYPE_ARRAY:
		return {"ok": false}

	var values: Array = []
	for item in data:
		var converted = _deserialize_plain_value(item, element_type)
		if not converted.ok:
			return {"ok": false}
		values.append(converted.value)

	match packed_array_type:
		TYPE_PACKED_BYTE_ARRAY:
			return _deserialized_value(PackedByteArray(values))
		TYPE_PACKED_INT32_ARRAY:
			return _deserialized_value(PackedInt32Array(values))
		TYPE_PACKED_INT64_ARRAY:
			return _deserialized_value(PackedInt64Array(values))
		TYPE_PACKED_FLOAT32_ARRAY:
			return _deserialized_value(PackedFloat32Array(values))
		TYPE_PACKED_FLOAT64_ARRAY:
			return _deserialized_value(PackedFloat64Array(values))
		TYPE_PACKED_STRING_ARRAY:
			return _deserialized_value(PackedStringArray(values))
	return {"ok": false}

## Converts primitive JSON values used by typed arrays and packed arrays.
func _deserialize_plain_value(data: Variant, expected_type: int) -> Dictionary:
	match expected_type:
		TYPE_BOOL:
			if typeof(data) == TYPE_BOOL:
				return _deserialized_value(data)
		TYPE_INT:
			if typeof(data) == TYPE_INT or typeof(data) == TYPE_FLOAT:
				return _deserialized_value(int(data))
		TYPE_FLOAT:
			if typeof(data) == TYPE_INT or typeof(data) == TYPE_FLOAT:
				return _deserialized_value(float(data))
		TYPE_STRING:
			if typeof(data) == TYPE_STRING:
				return _deserialized_value(data)
		TYPE_STRING_NAME:
			if typeof(data) == TYPE_STRING or typeof(data) == TYPE_STRING_NAME:
				return _deserialized_value(StringName(data))
		TYPE_DICTIONARY:
			if typeof(data) == TYPE_DICTIONARY:
				return _deserialized_value(data)
		TYPE_ARRAY:
			if typeof(data) == TYPE_ARRAY:
				return _deserialized_value(data)
		_:
			if typeof(data) == expected_type:
				return _deserialized_value(data)
	return {"ok": false}

## Returns the script declared for an object property, when discoverable.
func _script_from_property(property: Dictionary) -> Script:
	var class_name = str(property.get("class_name", ""))
	var script = _script_from_class_name(class_name)
	if script != null:
		return script

	var hint_string = str(property.get("hint_string", ""))
	return _script_from_hint_string(hint_string)

## Returns the script declared for an array element, when discoverable.
func _array_element_script(property: Dictionary) -> Script:
	return _script_from_hint_string(str(property.get("hint_string", "")))

## Returns the primitive type declared for an array element, when discoverable.
func _array_element_type(property: Dictionary) -> int:
	var hint_string = str(property.get("hint_string", ""))
	var first_character = hint_string.substr(0, 1)
	if hint_string == "" or first_character < "0" or first_character > "9":
		return TYPE_NIL
	var token = ""
	for index in range(hint_string.length()):
		var character = hint_string.substr(index, 1)
		if character >= "0" and character <= "9":
			token += character
		elif token != "":
			break
	if token == "":
		return TYPE_NIL
	return int(token)

## Resolves a script from a property hint string.
func _script_from_hint_string(hint_string: String) -> Script:
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

## Resolves a globally registered class name into its script.
func _script_from_class_name(class_name: String) -> Script:
	if class_name == "":
		return null
	for global_class in ProjectSettings.get_global_class_list():
		if str(global_class.get("class", "")) == class_name:
			var loaded = load(str(global_class.get("path", "")))
			if loaded is Script:
				return loaded
	return null

## Extracts a .gd script path embedded in a property hint string.
func _script_path_from_hint_string(hint_string: String) -> String:
	var start = hint_string.find("res://")
	if start == -1:
		return ""
	var end = hint_string.find(".gd", start)
	if end == -1:
		return ""
	return hint_string.substr(start, end - start + 3)

## Creates a successful internal conversion result.
func _deserialized_value(value: Variant) -> Dictionary:
	return {
		"ok": true,
		"value": value,
	}
