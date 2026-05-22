extends Object
## This codec utility serializes and deserializes values of several
## types in Godot (primitives and other values as well, like Vector2,
## Vector3, Color, ...).

const MessagePack = AlephVault__MMO__Common.Encoding.MessagePack
const Nothing = AlephVault__MMO__Common.Encoding.Nothing

const OBJECT_TO_DICTIONARY_METHOD := "to_dict"
const OBJECT_FROM_DICTIONARY_METHOD := "from_dict"

## Encodes a value into a MsgPack structure (as a PackedByteArray).
##
## The first stage is to convert the value to a recursive structure
## which is JSON-like (this means: arrays or dictionaries where the
## values are either more arrays or dictionaries, or primitive values
## like int, float, String, bool or null).
##
## Then, the MsgPack-encoding process. The result is a dictionary
## {status=OK or error, value=PackedByteArray}.
func encode(value: Variant) -> Dictionary:
	var encoded = MessagePack.encode(normalize(value))
	if encoded.status != null and encoded.status != OK:
		push_error("Codec.encode: failed to encode normalized value")
	return encoded

## Decodes a MsgPack payload and converts the normalized structure into
## the requested Godot type.
##
## The [type_] can be a Variant TYPE_* constant, a Script, or an object
## instance whose script should be used as the target object type.
##
## First, a MsgPack-decoding process. If it is successful, then it will
## be de-normalized again into the specific type detailed in the type_
## argument described earlier.
##
## The result is, still, a {status: OK or error, value} dictionary, like
## in the case of MsgPack's encode or decode methods.
func decode(value: PackedByteArray, type_: Variant) -> Dictionary:
	var decoded = MessagePack.decode(value)
	if decoded.status != null and decoded.status != OK:
		return decoded

	var denormalized = denormalize(decoded.value, type_)
	if not denormalized.ok:
		return {
			"status": ERR_INVALID_DATA,
			"value": denormalized.value,
		}
	return {
		"status": OK,
		"value": denormalized.value,
	}

## Converts a value into a recursive MessagePack-compatible structure.
##
## Object values must implement:
## - to_dict(codec: Object) -> Dictionary
func normalize(value: Variant) -> Variant:
	return _normalize(value)

## Converts normalized data into the requested Godot type.
##
## Object targets must implement:
## - from_dict(codec: Object, source: Dictionary) -> void
##
## The result is {ok: bool, value: Variant}. When [type_] is an object
## instance, the instance is edited in place and returned as value.
func denormalize(data: Variant, type_: Variant, current_value: Variant = null) -> Dictionary:
	return _denormalize(data, type_, current_value)

func _normalize(value: Variant) -> Variant:
	var value_type := typeof(value)
	if _is_packed_array_type(value_type):
		return _normalize_array(Array(value))

	match value_type:
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_VECTOR2:
			return [float(value.x), float(value.y)]
		TYPE_VECTOR2I:
			return [int(value.x), int(value.y)]
		TYPE_RECT2:
			return [_normalize(value.position), _normalize(value.size)]
		TYPE_RECT2I:
			return [_normalize(value.position), _normalize(value.size)]
		TYPE_VECTOR3:
			return [float(value.x), float(value.y), float(value.z)]
		TYPE_VECTOR3I:
			return [int(value.x), int(value.y), int(value.z)]
		TYPE_TRANSFORM2D:
			return [_normalize(value.x), _normalize(value.y), _normalize(value.origin)]
		TYPE_VECTOR4:
			return [float(value.x), float(value.y), float(value.z), float(value.w)]
		TYPE_VECTOR4I:
			return [int(value.x), int(value.y), int(value.z), int(value.w)]
		TYPE_PLANE:
			return [_normalize(value.normal), float(value.d)]
		TYPE_QUATERNION:
			return [float(value.x), float(value.y), float(value.z), float(value.w)]
		TYPE_AABB:
			return [_normalize(value.position), _normalize(value.size)]
		TYPE_BASIS:
			return [_normalize(value.x), _normalize(value.y), _normalize(value.z)]
		TYPE_TRANSFORM3D:
			return [_normalize(value.basis), _normalize(value.origin)]
		TYPE_PROJECTION:
			return [
				_normalize(value.x),
				_normalize(value.y),
				_normalize(value.z),
				_normalize(value.w)
			]
		TYPE_COLOR:
			return [float(value.r), float(value.g), float(value.b), float(value.a)]
		TYPE_STRING_NAME, TYPE_NODE_PATH, TYPE_RID:
			return str(value)
		TYPE_DICTIONARY:
			return _normalize_dictionary(value)
		TYPE_ARRAY:
			return _normalize_array(value)
		TYPE_CALLABLE, TYPE_SIGNAL:
			return _unsupported_value(value)
		TYPE_OBJECT:
			return _normalize_object(value)
		_:
			return _unsupported_value(value)

func _normalize_array(value: Array) -> Array:
	var result: Array = []
	for item in value:
		result.append(_normalize(item))
	return result

func _normalize_dictionary(value: Dictionary) -> Dictionary:
	var result := {}
	for key in value:
		result[_normalize(key)] = _normalize(value[key])
	return result

func _normalize_object(value: Object) -> Variant:
	if value == null:
		return null
	if value is Node or value is Resource:
		return _unsupported_value(value)
	if not value.has_method(OBJECT_TO_DICTIONARY_METHOD):
		push_error(
			"Codec.normalize: object values must implement %s(codec: Object) -> Dictionary"
			% OBJECT_TO_DICTIONARY_METHOD
		)
		return _unsupported_value(value)

	var source = value.call(OBJECT_TO_DICTIONARY_METHOD, self)
	if typeof(source) != TYPE_DICTIONARY:
		push_error(
			"Codec.normalize: object %s() must return a Dictionary"
			% OBJECT_TO_DICTIONARY_METHOD
		)
		return _unsupported_value(value)
	return _normalize_dictionary(source)

func _is_packed_array_type(value_type: int) -> bool:
	return value_type in [
		TYPE_PACKED_BYTE_ARRAY,
		TYPE_PACKED_INT32_ARRAY,
		TYPE_PACKED_INT64_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_FLOAT64_ARRAY,
		TYPE_PACKED_STRING_ARRAY,
		TYPE_PACKED_VECTOR2_ARRAY,
		TYPE_PACKED_VECTOR3_ARRAY,
		TYPE_PACKED_VECTOR4_ARRAY,
		TYPE_PACKED_COLOR_ARRAY,
	]

func _denormalize(data: Variant, type_: Variant, current_value: Variant = null) -> Dictionary:
	if type_ is Script:
		return _denormalize_object(data, type_)
	if type_ is Object:
		return _denormalize_object_instance_type(data, type_)
	if typeof(type_) == TYPE_INT and _is_variant_type(int(type_)):
		return _denormalize_type(data, int(type_), current_value)
	if typeof(type_) == TYPE_INT:
		return _denormalize_type(data, TYPE_INT, type_)
	return _denormalize_type(data, typeof(type_), type_)

func _denormalize_type(data: Variant, expected_type: int, current_value: Variant = null) -> Dictionary:
	if data == null:
		if expected_type == TYPE_NIL or expected_type == TYPE_OBJECT:
			return _ok(null)
		return _failed(data)

	match expected_type:
		TYPE_NIL:
			return _ok(data)
		TYPE_BOOL:
			if typeof(data) == TYPE_BOOL:
				return _ok(data)
		TYPE_INT:
			if _is_number(data):
				return _ok(int(data))
		TYPE_FLOAT:
			if _is_number(data):
				return _ok(float(data))
		TYPE_STRING:
			if typeof(data) == TYPE_STRING:
				return _ok(data)
		TYPE_VECTOR2:
			return _denormalize_vector2(data)
		TYPE_VECTOR2I:
			return _denormalize_vector2i(data)
		TYPE_RECT2:
			return _denormalize_rect2(data)
		TYPE_RECT2I:
			return _denormalize_rect2i(data)
		TYPE_VECTOR3:
			return _denormalize_vector3(data)
		TYPE_VECTOR3I:
			return _denormalize_vector3i(data)
		TYPE_TRANSFORM2D:
			return _denormalize_transform2d(data)
		TYPE_VECTOR4:
			return _denormalize_vector4(data)
		TYPE_VECTOR4I:
			return _denormalize_vector4i(data)
		TYPE_PLANE:
			return _denormalize_plane(data)
		TYPE_QUATERNION:
			return _denormalize_quaternion(data)
		TYPE_AABB:
			return _denormalize_aabb(data)
		TYPE_BASIS:
			return _denormalize_basis(data)
		TYPE_TRANSFORM3D:
			return _denormalize_transform3d(data)
		TYPE_PROJECTION:
			return _denormalize_projection(data)
		TYPE_COLOR:
			return _denormalize_color(data)
		TYPE_STRING_NAME:
			if typeof(data) == TYPE_STRING:
				return _ok(StringName(data))
		TYPE_NODE_PATH:
			if typeof(data) == TYPE_STRING:
				return _ok(NodePath(data))
		TYPE_RID:
			if typeof(data) == TYPE_STRING:
				push_error("Codec.decode: RID values cannot be restored from strings")
		TYPE_CALLABLE, TYPE_SIGNAL:
			push_error("Codec.decode: Callable and Signal values are not supported")
		TYPE_DICTIONARY:
			if typeof(data) == TYPE_DICTIONARY:
				return _ok(data)
		TYPE_ARRAY:
			if typeof(data) == TYPE_ARRAY:
				return _ok(data)
		TYPE_OBJECT:
			return _denormalize_object_instance_type(data, current_value)
		TYPE_PACKED_BYTE_ARRAY:
			return _denormalize_packed_array(data, TYPE_INT, TYPE_PACKED_BYTE_ARRAY)
		TYPE_PACKED_INT32_ARRAY:
			return _denormalize_packed_array(data, TYPE_INT, TYPE_PACKED_INT32_ARRAY)
		TYPE_PACKED_INT64_ARRAY:
			return _denormalize_packed_array(data, TYPE_INT, TYPE_PACKED_INT64_ARRAY)
		TYPE_PACKED_FLOAT32_ARRAY:
			return _denormalize_packed_array(data, TYPE_FLOAT, TYPE_PACKED_FLOAT32_ARRAY)
		TYPE_PACKED_FLOAT64_ARRAY:
			return _denormalize_packed_array(data, TYPE_FLOAT, TYPE_PACKED_FLOAT64_ARRAY)
		TYPE_PACKED_STRING_ARRAY:
			return _denormalize_packed_array(data, TYPE_STRING, TYPE_PACKED_STRING_ARRAY)
		TYPE_PACKED_VECTOR2_ARRAY:
			return _denormalize_packed_array(data, TYPE_VECTOR2, TYPE_PACKED_VECTOR2_ARRAY)
		TYPE_PACKED_VECTOR3_ARRAY:
			return _denormalize_packed_array(data, TYPE_VECTOR3, TYPE_PACKED_VECTOR3_ARRAY)
		TYPE_PACKED_VECTOR4_ARRAY:
			return _denormalize_packed_array(data, TYPE_VECTOR4, TYPE_PACKED_VECTOR4_ARRAY)
		TYPE_PACKED_COLOR_ARRAY:
			return _denormalize_packed_array(data, TYPE_COLOR, TYPE_PACKED_COLOR_ARRAY)
	return _failed(data)

func _denormalize_object_instance_type(data: Variant, object_type: Variant) -> Dictionary:
	if object_type == null:
		return _failed(data)
	if object_type is Node or object_type is Resource:
		push_error("Codec.decode: Node and Resource values are not supported")
		return _failed(data)

	var script = object_type.get_script() as Script
	if script == null:
		return _failed(data)
	return _denormalize_object(data, script, object_type)

func _denormalize_object(data: Variant, script: Script, target_instance: Object = null) -> Dictionary:
	if script == null or typeof(data) != TYPE_DICTIONARY:
		return _failed(data)

	var instance = target_instance
	if instance == null:
		instance = script.new()
	if instance is Node or instance is Resource:
		push_error("Codec.decode: Node and Resource values are not supported")
		return _failed(data)
	if not instance.has_method(OBJECT_FROM_DICTIONARY_METHOD):
		push_error(
			"Codec.decode: object targets must implement %s(codec: Object, source: Dictionary) -> void"
			% OBJECT_FROM_DICTIONARY_METHOD
		)
		return _failed(data)

	instance.call(OBJECT_FROM_DICTIONARY_METHOD, self, data)
	return _ok(instance)

func _denormalize_property(data: Variant, property: Dictionary, current_value: Variant) -> Dictionary:
	var expected_type = int(property.get("type", TYPE_NIL))
	if expected_type == TYPE_ARRAY:
		return _denormalize_array_property(data, property)
	if expected_type == TYPE_OBJECT:
		return _denormalize_object_property(data, property, current_value)
	return _denormalize_type(data, expected_type, current_value)

func _denormalize_object_property(
	data: Variant, property: Dictionary, current_value: Variant
) -> Dictionary:
	if data == null:
		return _ok(null)

	var script = _script_from_property(property)
	if script == null and current_value is Object:
		script = current_value.get_script() as Script
	if script == null:
		return _failed(data)
	return _denormalize_object(data, script)

func _denormalize_array_property(data: Variant, property: Dictionary) -> Dictionary:
	if typeof(data) != TYPE_ARRAY:
		return _failed(data)

	var element_script = _array_element_script(property)
	var element_type = _array_element_type(property)
	var result: Array = []
	for item in data:
		if element_script != null:
			var object_item = _denormalize_object(item, element_script)
			if not object_item.ok:
				return _failed(data)
			result.append(object_item.value)
		elif element_type != TYPE_NIL:
			var typed_item = _denormalize_type(item, element_type)
			if not typed_item.ok:
				return _failed(data)
			result.append(typed_item.value)
		else:
			result.append(item)
	return _ok(result)

func _denormalize_packed_array(
	data: Variant, element_type: int, packed_array_type: int
) -> Dictionary:
	if typeof(data) != TYPE_ARRAY:
		return _failed(data)

	var values: Array = []
	for item in data:
		var converted = _denormalize_type(item, element_type)
		if not converted.ok:
			return _failed(data)
		values.append(converted.value)

	match packed_array_type:
		TYPE_PACKED_BYTE_ARRAY:
			return _ok(PackedByteArray(values))
		TYPE_PACKED_INT32_ARRAY:
			return _ok(PackedInt32Array(values))
		TYPE_PACKED_INT64_ARRAY:
			return _ok(PackedInt64Array(values))
		TYPE_PACKED_FLOAT32_ARRAY:
			return _ok(PackedFloat32Array(values))
		TYPE_PACKED_FLOAT64_ARRAY:
			return _ok(PackedFloat64Array(values))
		TYPE_PACKED_STRING_ARRAY:
			return _ok(PackedStringArray(values))
		TYPE_PACKED_VECTOR2_ARRAY:
			return _ok(PackedVector2Array(values))
		TYPE_PACKED_VECTOR3_ARRAY:
			return _ok(PackedVector3Array(values))
		TYPE_PACKED_VECTOR4_ARRAY:
			return _ok(PackedVector4Array(values))
		TYPE_PACKED_COLOR_ARRAY:
			return _ok(PackedColorArray(values))
	return _failed(data)

func _denormalize_vector2(data: Variant) -> Dictionary:
	if _is_array_size(data, 2) and _is_number(data[0]) and _is_number(data[1]):
		return _ok(Vector2(float(data[0]), float(data[1])))
	return _failed(data)

func _denormalize_vector2i(data: Variant) -> Dictionary:
	if _is_array_size(data, 2) and _is_number(data[0]) and _is_number(data[1]):
		return _ok(Vector2i(int(data[0]), int(data[1])))
	return _failed(data)

func _denormalize_rect2(data: Variant) -> Dictionary:
	if not _is_array_size(data, 2):
		return _failed(data)
	var position = _denormalize_vector2(data[0])
	var size = _denormalize_vector2(data[1])
	if position.ok and size.ok:
		return _ok(Rect2(position.value, size.value))
	return _failed(data)

func _denormalize_rect2i(data: Variant) -> Dictionary:
	if not _is_array_size(data, 2):
		return _failed(data)
	var position = _denormalize_vector2i(data[0])
	var size = _denormalize_vector2i(data[1])
	if position.ok and size.ok:
		return _ok(Rect2i(position.value, size.value))
	return _failed(data)

func _denormalize_vector3(data: Variant) -> Dictionary:
	if _is_array_size(data, 3) and _all_numbers(data):
		return _ok(Vector3(float(data[0]), float(data[1]), float(data[2])))
	return _failed(data)

func _denormalize_vector3i(data: Variant) -> Dictionary:
	if _is_array_size(data, 3) and _all_numbers(data):
		return _ok(Vector3i(int(data[0]), int(data[1]), int(data[2])))
	return _failed(data)

func _denormalize_transform2d(data: Variant) -> Dictionary:
	if not _is_array_size(data, 3):
		return _failed(data)
	var x = _denormalize_vector2(data[0])
	var y = _denormalize_vector2(data[1])
	var origin = _denormalize_vector2(data[2])
	if x.ok and y.ok and origin.ok:
		return _ok(Transform2D(x.value, y.value, origin.value))
	return _failed(data)

func _denormalize_vector4(data: Variant) -> Dictionary:
	if _is_array_size(data, 4) and _all_numbers(data):
		return _ok(Vector4(float(data[0]), float(data[1]), float(data[2]), float(data[3])))
	return _failed(data)

func _denormalize_vector4i(data: Variant) -> Dictionary:
	if _is_array_size(data, 4) and _all_numbers(data):
		return _ok(Vector4i(int(data[0]), int(data[1]), int(data[2]), int(data[3])))
	return _failed(data)

func _denormalize_plane(data: Variant) -> Dictionary:
	if not _is_array_size(data, 2) or not _is_number(data[1]):
		return _failed(data)
	var normal = _denormalize_vector3(data[0])
	if normal.ok:
		return _ok(Plane(normal.value, float(data[1])))
	return _failed(data)

func _denormalize_quaternion(data: Variant) -> Dictionary:
	if _is_array_size(data, 4) and _all_numbers(data):
		return _ok(Quaternion(float(data[0]), float(data[1]), float(data[2]), float(data[3])))
	return _failed(data)

func _denormalize_aabb(data: Variant) -> Dictionary:
	if not _is_array_size(data, 2):
		return _failed(data)
	var position = _denormalize_vector3(data[0])
	var size = _denormalize_vector3(data[1])
	if position.ok and size.ok:
		return _ok(AABB(position.value, size.value))
	return _failed(data)

func _denormalize_basis(data: Variant) -> Dictionary:
	if not _is_array_size(data, 3):
		return _failed(data)
	var x = _denormalize_vector3(data[0])
	var y = _denormalize_vector3(data[1])
	var z = _denormalize_vector3(data[2])
	if x.ok and y.ok and z.ok:
		return _ok(Basis(x.value, y.value, z.value))
	return _failed(data)

func _denormalize_transform3d(data: Variant) -> Dictionary:
	if not _is_array_size(data, 2):
		return _failed(data)
	var basis = _denormalize_basis(data[0])
	var origin = _denormalize_vector3(data[1])
	if basis.ok and origin.ok:
		return _ok(Transform3D(basis.value, origin.value))
	return _failed(data)

func _denormalize_projection(data: Variant) -> Dictionary:
	if not _is_array_size(data, 4):
		return _failed(data)
	var x = _denormalize_vector4(data[0])
	var y = _denormalize_vector4(data[1])
	var z = _denormalize_vector4(data[2])
	var w = _denormalize_vector4(data[3])
	if x.ok and y.ok and z.ok and w.ok:
		return _ok(Projection(x.value, y.value, z.value, w.value))
	return _failed(data)

func _denormalize_color(data: Variant) -> Dictionary:
	if _is_array_size(data, 4) and _all_numbers(data):
		return _ok(Color(float(data[0]), float(data[1]), float(data[2]), float(data[3])))
	return _failed(data)

func _is_array_size(data: Variant, size: int) -> bool:
	return typeof(data) == TYPE_ARRAY and data.size() == size

func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

func _all_numbers(values: Array) -> bool:
	for value in values:
		if not _is_number(value):
			return false
	return true

func _is_variant_type(value: int) -> bool:
	return value in [
		TYPE_NIL,
		TYPE_BOOL,
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_STRING,
		TYPE_VECTOR2,
		TYPE_VECTOR2I,
		TYPE_RECT2,
		TYPE_RECT2I,
		TYPE_VECTOR3,
		TYPE_VECTOR3I,
		TYPE_TRANSFORM2D,
		TYPE_VECTOR4,
		TYPE_VECTOR4I,
		TYPE_PLANE,
		TYPE_QUATERNION,
		TYPE_AABB,
		TYPE_BASIS,
		TYPE_TRANSFORM3D,
		TYPE_PROJECTION,
		TYPE_COLOR,
		TYPE_STRING_NAME,
		TYPE_NODE_PATH,
		TYPE_RID,
		TYPE_OBJECT,
		TYPE_CALLABLE,
		TYPE_SIGNAL,
		TYPE_DICTIONARY,
		TYPE_ARRAY,
		TYPE_PACKED_BYTE_ARRAY,
		TYPE_PACKED_INT32_ARRAY,
		TYPE_PACKED_INT64_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_FLOAT64_ARRAY,
		TYPE_PACKED_STRING_ARRAY,
		TYPE_PACKED_VECTOR2_ARRAY,
		TYPE_PACKED_VECTOR3_ARRAY,
		TYPE_PACKED_VECTOR4_ARRAY,
		TYPE_PACKED_COLOR_ARRAY,
	]

func _array_element_script(property: Dictionary) -> Script:
	return _script_from_hint_string(str(property.get("hint_string", "")))

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

func _script_from_property(property: Dictionary) -> Script:
	var classname = str(property.get("class_name", ""))
	var script = _script_from_class_name(classname)
	if script != null:
		return script
	return _script_from_hint_string(str(property.get("hint_string", "")))

func _script_from_hint_string(hint_string: String) -> Script:
	var path = _script_path_from_hint_string(hint_string)
	if path != "":
		var loaded = load(path)
		if loaded is Script:
			return loaded

	for global_class in ProjectSettings.get_global_class_list():
		var classname = str(global_class.get("class", ""))
		if classname != "" and hint_string.find(classname) != -1:
			return _script_from_class_name(classname)
	return null

func _script_from_class_name(classname: String) -> Script:
	if classname == "":
		return null
	for global_class in ProjectSettings.get_global_class_list():
		if str(global_class.get("class", "")) == classname:
			var loaded = load(str(global_class.get("path", "")))
			if loaded is Script:
				return loaded
	return null

func _script_path_from_hint_string(hint_string: String) -> String:
	var start = hint_string.find("res://")
	if start == -1:
		return ""
	var end = hint_string.find(".gd", start)
	if end == -1:
		return ""
	return hint_string.substr(start, end - start + 3)

func _ok(value: Variant) -> Dictionary:
	return {
		"ok": true,
		"value": value,
	}

func _failed(value: Variant = null) -> Dictionary:
	return {
		"ok": false,
		"value": value,
	}

func _unsupported_value(value: Variant) -> Variant:
	push_error("Codec._normalize: unsupported value type: %s" % typeof(value))
	return value
