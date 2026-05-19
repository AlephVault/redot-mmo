extends Object
## This codec utility serializes and deserializes values of several
## types in Godot (primitives and other values as well, like Vector2,
## Vector3, Color, ...).

const MessagePack = AlephVault__MMO__Common.Encoding.MessagePack
const Nothing = AlephVault__MMO__Common.Encoding.Nothing

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
	var encoded = MessagePack.encode(_normalize(value))
	if encoded.status != null and encoded.status != OK:
		push_error("Codec.encode: failed to encode normalized value")
	return encoded

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

	var result := {}
	for property in value.get_property_list():
		var property_name = str(property.get("name", ""))
		var usage = int(property.get("usage", 0))
		if property_name == "script" or (usage & PROPERTY_USAGE_STORAGE) == 0:
			continue
		result[property_name] = _normalize(value.get(property_name))
	return result

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

func _unsupported_value(value: Variant) -> Variant:
	push_error("Codec._normalize: unsupported value type: %s" % typeof(value))
	return value
