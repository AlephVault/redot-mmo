extends RefCounted

const Result = AlephVault__MMO__Storage.Types.Result
const ResultCode = AlephVault__MMO__Storage.Types.ResultCode
const Authorization = AlephVault__MMO__Storage.StandardHttp.Authorization

# Base class for standard HTTP storage resource handles.
#
# This class stores the resource name, base endpoint, and authorization shared
# by simple and list resources. It also contains the shallow JSON-to-script
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
## Matching JSON keys are copied into stored properties on the new instance.
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
## This mapper is intentionally shallow: it assigns values whose JSON keys
## match stored properties on the script instance, but it does not recursively
## instantiate nested custom classes.
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
		writable_properties[property_name] = true

	for key in data:
		var property_name = str(key)
		if writable_properties.has(property_name):
			instance.set(property_name, data[key])

	return {
		"ok": true,
		"element": instance,
	}
