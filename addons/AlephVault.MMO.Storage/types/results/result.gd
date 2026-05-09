extends RefCounted

const ResultCode = AlephVault__MMO__Storage.Types.ResultCode

# Result returned by storage resource operations.
#
# Depending on [code], one of [element], [elements], [created_id],
# [validation_errors], or [request_error_code] may be populated.
var code: int = ResultCode.Ok
var validation_errors: Variant = null
var request_error_code: String = ""
var created_id: String = ""
var element: Variant = null
var elements: Array = []

## Creates an OK result with a single element.
static func ok(element: Variant = null) -> AlephVault__MMO__Storage.Types.Result:
	var result = new()
	result.code = ResultCode.Ok
	result.element = element
	return result

## Creates an OK result with many elements.
static func ok_many(elements: Array) -> AlephVault__MMO__Storage.Types.Result:
	var result = new()
	result.code = ResultCode.Ok
	result.elements = elements
	return result

## Creates a Created result with the id returned by the storage service.
static func created(id: String = "") -> AlephVault__MMO__Storage.Types.Result:
	var result = new()
	result.code = ResultCode.Created
	result.created_id = id
	return result

## Creates a failure result.
##
## [validation_errors] is used for schema validation failures, and
## [request_error_code] is used for custom bad-request codes.
static func failed(
	code: int, validation_errors: Variant = null, request_error_code: String = ""
) -> AlephVault__MMO__Storage.Types.Result:
	var result = new()
	result.code = code
	result.validation_errors = validation_errors
	result.request_error_code = request_error_code
	return result
