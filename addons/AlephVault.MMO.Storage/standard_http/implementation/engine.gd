extends Object

const ResultCode = AlephVault__MMO__Storage.Types.ResultCode
const Authorization = AlephVault__MMO__Storage.StandardHttp.Authorization
const Cursor = AlephVault__MMO__Storage.StandardHttp.Cursor

const _METHOD_PATCH = HTTPClient.METHOD_PATCH

# Low-level standard HTTP storage engine.
#
# The engine performs HTTP requests and returns normalized dictionaries with:
# ok, data, code, validation_errors, request_error_code, and created_id.

## Sends GET to a list endpoint with the cursor query string.
static func list(
	endpoint: String,
	authorization: Authorization,
	cursor: Cursor
) -> Dictionary:
	var url = "%s?%s" % [_clean_endpoint(endpoint), cursor.query_string()]
	return await _send_json(url, HTTPClient.METHOD_GET, authorization)

## Sends GET to an item or simple-resource endpoint.
static func one(endpoint: String, authorization: Authorization) -> Dictionary:
	return await _send_json(_clean_endpoint(endpoint), HTTPClient.METHOD_GET, authorization)

## Sends POST to create a simple resource or list item.
##
## If the response is an object containing "id", created_id is populated.
static func create(
	endpoint: String, authorization: Authorization, data: Variant
) -> Dictionary:
	var response = await _send_json(
		_clean_endpoint(endpoint), HTTPClient.METHOD_POST, authorization, data, true, true
	)
	if not response.ok:
		return response
	if typeof(response.data) == TYPE_DICTIONARY and response.data.has("id"):
		response.created_id = str(response.data.id)
	else:
		response.created_id = ""
	return response

## Sends PATCH with a MongoDB-style patch body.
static func update(
	endpoint: String, authorization: Authorization, patch: Variant
) -> Dictionary:
	return await _send_json(_clean_endpoint(endpoint), _METHOD_PATCH, authorization, patch, true, true)

## Sends PUT with a full replacement body.
static func replace(
	endpoint: String,
	authorization: Authorization,
	replacement: Variant
) -> Dictionary:
	return await _send_json(_clean_endpoint(endpoint), HTTPClient.METHOD_PUT, authorization, replacement, true, true)

## Sends DELETE to remove a simple resource or list item.
static func delete(endpoint: String, authorization: Authorization) -> Dictionary:
	return await _send_json(_clean_endpoint(endpoint), HTTPClient.METHOD_DELETE, authorization, null, true, true)

## Sends GET to a custom view endpoint.
##
## [request_args] are URL-encoded and appended as a query string.
static func view_to_json(
	endpoint: String,
	authorization: Authorization,
	request_args: Dictionary = {}
) -> Dictionary:
	var url = _url_with_args(_clean_endpoint(endpoint), request_args)
	return await _send_json(url, HTTPClient.METHOD_GET, authorization, null, true, true)

## Sends POST to a custom operation endpoint.
##
## [body] is serialized as JSON when present.
static func operation_to_json(
	endpoint: String,
	authorization: Authorization,
	request_args: Dictionary = {},
	body: Variant = null
) -> Dictionary:
	var url = _url_with_args(_clean_endpoint(endpoint), request_args)
	return await _send_json(url, HTTPClient.METHOD_POST, authorization, body, true, true)

## Sends a JSON HTTP request and normalizes transport, status, and JSON errors.
static func _send_json(
	url: String,
	method: int,
	authorization: Authorization,
	body: Variant = null,
	include_bad_request: bool = false, include_conflict: bool = false
) -> Dictionary:
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return _failure(ResultCode.ClientError)

	var request = HTTPRequest.new()
	tree.root.add_child(request)

	var headers: PackedStringArray = [
		"Authorization: %s %s" % [authorization.scheme, authorization.value]
	]
	if include_bad_request:
		headers.append("Content-Type: application/json")
	var body_text = ""
	if body != null:
		var serialized = JSON.stringify(body)
		if serialized == "":
			request.queue_free()
			return _failure(ResultCode.FormatError)
		body_text = serialized

	var request_error = request.request(url, headers, method, body_text)
	if request_error != OK:
		request.queue_free()
		return _failure(ResultCode.ClientError)

	var completed = await request.request_completed
	request.queue_free()
	var result_code: int = completed[0]
	var status: int = completed[1]
	var response_body: PackedByteArray = completed[3]

	if result_code == HTTPRequest.RESULT_CANT_CONNECT or result_code == HTTPRequest.RESULT_CANT_RESOLVE:
		return _failure(ResultCode.Unreachable)
	if result_code == HTTPRequest.RESULT_TIMEOUT:
		return _failure(ResultCode.Timeout)
	if result_code != HTTPRequest.RESULT_SUCCESS:
		return _failure(ResultCode.ClientError)

	var status_failure = _failure_from_status(status, response_body, include_bad_request, include_conflict)
	if not status_failure.ok:
		return status_failure

	var text = response_body.get_string_from_utf8()
	if text.strip_edges() == "":
		return _success(null)

	var json = JSON.new()
	if json.parse(text) != OK:
		return _failure(ResultCode.FormatError)
	return _success(json.data)

## Converts HTTP status codes into storage result codes.
static func _failure_from_status(
	status: int, body: PackedByteArray, include_bad_request: bool, include_conflict: bool
) -> Dictionary:
	match status:
		401:
			return _failure(ResultCode.Unauthorized)
		403:
			return _failure(ResultCode.Forbidden)
		404, 410:
			return _failure(ResultCode.DoesNotExist)
		405:
			return _failure(ResultCode.Unsupported)
		406, 415:
			return _failure(ResultCode.FormatError)
		500:
			return _failure(ResultCode.InternalError)
		502:
			return _failure(ResultCode.Unreachable)
		503:
			return _failure(ResultCode.ServiceUnavailable)
		504:
			return _failure(ResultCode.Timeout)

	if include_bad_request and status == 400:
		return _bad_request_failure(body)
	if include_conflict and status == 409:
		return _conflict_failure(body)
	if status > 500:
		return _failure(ResultCode.ServerError)
	if status > 400:
		return _failure(ResultCode.ClientError)
	return _success(null)

## Parses 400 response bodies into authorization, validation, format, or custom
## bad-request failures.
static func _bad_request_failure(body: PackedByteArray) -> Dictionary:
	var data = _parse_body_or_null(body)
	if typeof(data) != TYPE_DICTIONARY or not data.has("code"):
		return _failure(ResultCode.FormatError)

	match str(data.code):
		"authorization:missing-header", "authorization:bad-scheme":
			return _failure(ResultCode.Unauthorized)
		"schema:invalid":
			return _failure(ResultCode.ValidationError, data.get("errors"))
		"format:unexpected":
			return _failure(ResultCode.FormatError)
		_:
			return _failure(ResultCode.BadRequest, null, str(data.code))

## Parses 409 response bodies into known conflict result codes.
static func _conflict_failure(body: PackedByteArray) -> Dictionary:
	var data = _parse_body_or_null(body)
	if typeof(data) != TYPE_DICTIONARY or not data.has("code"):
		return _failure(ResultCode.Conflict)

	match str(data.code):
		"already-exists":
			return _failure(ResultCode.AlreadyExists)
		"in-use":
			return _failure(ResultCode.InUse)
		"duplicate-key":
			return _failure(ResultCode.DuplicateKey)
		_:
			return _failure(ResultCode.Conflict)

## Parses a JSON response body, returning null when parsing fails.
static func _parse_body_or_null(body: PackedByteArray) -> Variant:
	var text = body.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data

## Appends URL-encoded query arguments to an endpoint.
static func _url_with_args(endpoint: String, request_args: Dictionary) -> String:
	if request_args == null or request_args.is_empty():
		return endpoint
	var args: Array[String] = []
	for key in request_args:
		args.append("%s=%s" % [str(key).uri_encode(), str(request_args[key]).uri_encode()])
	return "%s?%s" % [endpoint, "&".join(args)]

## Removes any query string already present in the endpoint.
static func _clean_endpoint(endpoint: String) -> String:
	return endpoint.get_slice("?", 0)

## Creates a normalized successful engine response.
static func _success(data: Variant) -> Dictionary:
	return {
		"ok": true,
		"data": data,
		"code": ResultCode.Ok,
		"validation_errors": null,
		"request_error_code": "",
		"created_id": "",
	}

## Creates a normalized failed engine response.
static func _failure(code: int, validation_errors: Variant = null, request_error_code: String = "") -> Dictionary:
	return {
		"ok": false,
		"data": null,
		"code": code,
		"validation_errors": validation_errors,
		"request_error_code": request_error_code,
		"created_id": "",
	}
