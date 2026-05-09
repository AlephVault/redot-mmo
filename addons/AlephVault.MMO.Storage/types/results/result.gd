extends RefCounted

const ResultCode = AlephVault__MMO__Storage.Types.ResultCode

var code: int = ResultCode.Ok
var validation_errors: Variant = null
var request_error_code: String = ""
var created_id: String = ""
var element: Variant = null
var elements: Array = []

static func ok(element: Variant = null) -> AlephVault__MMO__Storage.Types.Result:
	var result = new()
	result.code = ResultCode.Ok
	result.element = element
	return result

static func ok_many(elements: Array) -> AlephVault__MMO__Storage.Types.Result:
	var result = new()
	result.code = ResultCode.Ok
	result.elements = elements
	return result

static func created(id: String = "") -> AlephVault__MMO__Storage.Types.Result:
	var result = new()
	result.code = ResultCode.Created
	result.created_id = id
	return result

static func failed(
	code: int, validation_errors: Variant = null, request_error_code: String = ""
) -> AlephVault__MMO__Storage.Types.Result:
	var result = new()
	result.code = code
	result.validation_errors = validation_errors
	result.request_error_code = request_error_code
	return result
