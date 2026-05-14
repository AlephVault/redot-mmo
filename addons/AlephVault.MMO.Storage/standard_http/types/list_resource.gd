extends "res://addons/AlephVault.MMO.Storage/standard_http/types/resource.gd"

const EngineImpl = AlephVault__MMO__Storage.StandardHttp.Engine
const Result = AlephVault__MMO__Storage.Types.Result
const ResultCode = AlephVault__MMO__Storage.Types.ResultCode
const Cursor = AlephVault__MMO__Storage.StandardHttp.Cursor
const Authorization = AlephVault__MMO__Storage.StandardHttp.Authorization

# Handle for a standard HTTP list resource.
#
# A list resource represents a collection at "<base_endpoint>/<name>".
# Item-level operations address "<resource>/<id>" where ids are strings.
var element_class: Script

func _init(
	name_: String = "",
	base_endpoint_: String = "",
	authorization_: Authorization = null,
	element_class_: Script = null
) -> void:
	super(name_, base_endpoint_, authorization_)
	assert(element_class_ != null, "An element class is required")
	element_class = element_class_

## Lists resources and maps each JSON object into the bound element type.
##
## Returns FormatError if the response is not an array of objects.
func list(cursor: Cursor) -> Result:
	var response = await EngineImpl.list(_endpoint(), authorization, cursor)
	return _wrap_deserialized_array_response(response, element_class)

## Lists resources using [cursor] and returns raw JSON-compatible elements.
##
## On success, [Result.elements] contains the decoded array.
func list_json(cursor: Cursor) -> Result:
	var response = await EngineImpl.list(_endpoint(), authorization, cursor)
	if not response.ok:
		return _wrap_response(response, Result.ok_many([]))
	if typeof(response.data) != TYPE_ARRAY:
		return Result.failed(ResultCode.FormatError)
	return Result.ok_many(response.data)

## Creates a new list item by POSTing [body].
##
## On success, the result code is Created and [Result.created_id] contains the
## id returned by the service when one is present.
func create(body: Variant) -> Result:
	var response = await EngineImpl.create(_endpoint(), authorization, body)
	return _wrap_response(response, Result.created(response.created_id))

## Reads a list item and maps the JSON object into the bound element type.
##
## Returns FormatError when the response is not a JSON object or cannot be
## mapped into an instance of the configured script.
func read(id: String) -> Result:
	var response = await EngineImpl.one(_item_endpoint(id), authorization)
	return _wrap_deserialized_response(response, element_class)

## Reads a list item as raw JSON-compatible data.
##
## On success, [Result.element] contains the decoded response.
func read_json(id: String) -> Result:
	var response = await EngineImpl.one(_item_endpoint(id), authorization)
	return _wrap_response(response, Result.ok(response.data))

## Applies a MongoDB-style patch to a list item.
##
## Example: {"$set": {"name": "Alice"}}
func update(id: String, changes: Dictionary) -> Result:
	var response = await EngineImpl.update(_item_endpoint(id), authorization, changes)
	return _wrap_response(response, Result.ok())

## Replaces a list item by PUTing [replacement].
func replace(id: String, replacement: Variant) -> Result:
	var response = await EngineImpl.replace(_item_endpoint(id), authorization, replacement)
	return _wrap_response(response, Result.ok())

## Deletes a list item.
func delete(id: String) -> Result:
	var response = await EngineImpl.delete(_item_endpoint(id), authorization)
	return _wrap_response(response, Result.ok())

## Calls a read-only custom method over the whole list.
##
## The endpoint is "<resource>/~<method>". A JSON object response is expected.
func view_to_json(method: String, args: Dictionary = {}) -> Result:
	var response = await EngineImpl.view_to_json(_method_endpoint(method), authorization, args)
	if response.ok and typeof(response.data) != TYPE_DICTIONARY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a write-capable custom method over the whole list.
##
## The endpoint is "<resource>/~<method>". A JSON object response is expected.
func operation_to_json(
	method: String, args: Dictionary = {}, body: Variant = null
) -> Result:
	var response = await EngineImpl.operation_to_json(_method_endpoint(method), authorization, args, body)
	if response.ok and typeof(response.data) != TYPE_DICTIONARY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a read-only custom method over one list item.
##
## The endpoint is "<resource>/<id>/~<method>". A JSON object response is expected.
func item_view_to_json(
	id: String, method: String, args: Dictionary = {}
) -> Result:
	var response = await EngineImpl.view_to_json(_item_method_endpoint(id, method), authorization, args)
	if response.ok and typeof(response.data) != TYPE_DICTIONARY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a write-capable custom method over one list item.
##
## The endpoint is "<resource>/<id>/~<method>". A JSON object response is expected.
func item_operation_to_json(
	id: String, method: String, args: Dictionary = {}, body: Variant = null
) -> Result:
	var response = await EngineImpl.operation_to_json(_item_method_endpoint(id, method), authorization, args, body)
	if response.ok and typeof(response.data) != TYPE_DICTIONARY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a read-only custom method over the whole list.
##
## A JSON array response is expected.
func view_to_json_array(method: String, args: Dictionary = {}) -> Result:
	var response = await EngineImpl.view_to_json(_method_endpoint(method), authorization, args)
	if response.ok and typeof(response.data) != TYPE_ARRAY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a write-capable custom method over the whole list.
##
## A JSON array response is expected.
func operation_to_json_array(
	method: String, args: Dictionary = {}, body: Variant = null
) -> Result:
	var response = await EngineImpl.operation_to_json(_method_endpoint(method), authorization, args, body)
	if response.ok and typeof(response.data) != TYPE_ARRAY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a read-only custom method over one list item.
##
## A JSON array response is expected.
func item_view_to_json_array(
	id: String, method: String, args: Dictionary = {}
) -> Result:
	var response = await EngineImpl.view_to_json(_item_method_endpoint(id, method), authorization, args)
	if response.ok and typeof(response.data) != TYPE_ARRAY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a write-capable custom method over one list item.
##
## A JSON array response is expected.
func item_operation_to_json_array(
	id: String, method: String, args: Dictionary = {}, body: Variant = null
) -> Result:
	var response = await EngineImpl.operation_to_json(_item_method_endpoint(id, method), authorization, args, body)
	if response.ok and typeof(response.data) != TYPE_ARRAY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a read-only custom method over the whole list and maps the response.
##
## Use view_to_json() for raw Dictionary responses.
func view_to(method: String, args: Dictionary, response_class: Script) -> Result:
	var response = await EngineImpl.view_to_json(_method_endpoint(method), authorization, args)
	return _wrap_deserialized_response(response, response_class)

## Calls a write-capable custom method over the whole list and maps the response.
##
## Use operation_to_json() for raw Dictionary responses.
func operation_to(
	method: String, args: Dictionary, response_class: Script, body: Variant = null
) -> Result:
	var response = await EngineImpl.operation_to_json(_method_endpoint(method), authorization, args, body)
	return _wrap_deserialized_response(response, response_class)

## Calls a read-only custom method over one item and maps the response.
##
## Use item_view_to_json() for raw Dictionary responses.
func item_view_to(
	id: String, method: String, args: Dictionary, response_class: Script
) -> Result:
	var response = await EngineImpl.view_to_json(_item_method_endpoint(id, method), authorization, args)
	return _wrap_deserialized_response(response, response_class)

## Calls a write-capable custom method over one item and maps the response.
##
## Use item_operation_to_json() for raw Dictionary responses.
func item_operation_to(
	id: String, method: String, args: Dictionary, response_class: Script, body: Variant = null
) -> Result:
	var response = await EngineImpl.operation_to_json(_item_method_endpoint(id, method), authorization, args, body)
	return _wrap_deserialized_response(response, response_class)

## Returns the endpoint for one list item.
func _item_endpoint(id: String) -> String:
	return "%s/%s" % [_endpoint(), id.uri_encode()]

## Returns the endpoint for a custom method over one list item.
func _item_method_endpoint(id: String, method: String) -> String:
	return "%s/~%s" % [_item_endpoint(id), method]
