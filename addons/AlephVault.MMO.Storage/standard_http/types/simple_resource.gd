extends AlephVault__MMO__Storage.StandardHttp.BaseResource

const EngineImpl = AlephVault__MMO__Storage.StandardHttp.RequestEngine
const Result = AlephVault__MMO__Storage.Types.Result
const ResultCode = AlephVault__MMO__Storage.Types.ResultCode
const Authorization = AlephVault__MMO__Storage.StandardHttp.Authorization

# Handle for a standard HTTP simple resource.
#
# A simple resource represents one object at "<base_endpoint>/<name>".
# Operations return Result instances instead of throwing storage errors.
var response_class: Script

func _init(
	name_: String = "",
	base_endpoint_: String = "",
	authorization_: Authorization = null,
	response_class_: Script = null
) -> void:
	super(name_, base_endpoint_, authorization_)
	assert(response_class_ != null, "A response class is required")
	response_class = response_class_

## Creates the simple resource by POSTing [body].
##
## On success, the result code is Created and [Result.created_id] contains the
## id returned by the service when one is present.
func create(body: Variant) -> Result:
	var response = await EngineImpl.create(_endpoint(), authorization, body)
	return _wrap_response(response, Result.created(response.created_id))

## Reads the simple resource and maps the JSON object into the bound type.
##
## Returns FormatError when the response is not a JSON object or cannot be
## mapped into an instance of the configured script.
func read() -> Result:
	var response = await EngineImpl.one(_endpoint(), authorization)
	return _wrap_deserialized_response(response, response_class)

## Reads the simple resource as raw JSON-compatible data.
##
## On success, [Result.element] contains the decoded response.
func read_json() -> Result:
	var response = await EngineImpl.one(_endpoint(), authorization)
	return _wrap_response(response, Result.ok(response.data))

## Applies a MongoDB-style patch to the simple resource.
##
## Example: {"$set": {"name": "Alice"}}
func update(changes: Dictionary) -> Result:
	var response = await EngineImpl.update(_endpoint(), authorization, changes)
	return _wrap_response(response, Result.ok())

## Replaces the simple resource by PUTing [replacement].
func replace(replacement: Variant) -> Result:
	var response = await EngineImpl.replace(_endpoint(), authorization, replacement)
	return _wrap_response(response, Result.ok())

## Deletes the simple resource.
func delete() -> Result:
	var response = await EngineImpl.delete(_endpoint(), authorization)
	return _wrap_response(response, Result.ok())

## Calls a read-only custom method and expects a JSON object response.
##
## The endpoint is "<resource>/~<method>". Query arguments are URL-encoded.
func view_to_json(method: String, args: Dictionary = {}) -> Result:
	var response = await EngineImpl.view_to_json(_method_endpoint(method), authorization, args)
	if response.ok and typeof(response.data) != TYPE_DICTIONARY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a write-capable custom method and expects a JSON object response.
##
## The endpoint is "<resource>/~<method>". [body] is sent as JSON when present.
func operation_to_json(
	method: String, args: Dictionary = {}, body: Variant = null
) -> Result:
	var response = await EngineImpl.operation_to_json(_method_endpoint(method), authorization, args, body)
	if response.ok and typeof(response.data) != TYPE_DICTIONARY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a read-only custom method and expects a JSON array response.
func view_to_json_array(method: String, args: Dictionary = {}) -> Result:
	var response = await EngineImpl.view_to_json(_method_endpoint(method), authorization, args)
	if response.ok and typeof(response.data) != TYPE_ARRAY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a write-capable custom method and expects a JSON array response.
func operation_to_json_array(
	method: String, args: Dictionary = {}, body: Variant = null
) -> Result:
	var response = await EngineImpl.operation_to_json(_method_endpoint(method), authorization, args, body)
	if response.ok and typeof(response.data) != TYPE_ARRAY:
		return Result.failed(ResultCode.FormatError)
	return _wrap_response(response, Result.ok(response.data))

## Calls a read-only custom method and maps the JSON object response.
##
## Use view_to_json() for raw Dictionary responses.
func view_to(method: String, args: Dictionary, response_class: Script) -> Result:
	var response = await EngineImpl.view_to_json(_method_endpoint(method), authorization, args)
	return _wrap_deserialized_response(response, response_class)

## Calls a write-capable custom method and maps the JSON object response.
##
## Use operation_to_json() for raw Dictionary responses.
func operation_to(
	method: String, args: Dictionary, response_class: Script, body: Variant = null
) -> Result:
	var response = await EngineImpl.operation_to_json(_method_endpoint(method), authorization, args, body)
	return _wrap_deserialized_response(response, response_class)
