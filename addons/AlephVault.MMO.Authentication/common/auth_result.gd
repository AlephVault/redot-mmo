extends RefCounted

var accepted: bool = false
var payload: Variant = null
var account_id: Variant = null
var reason: Variant = null

static func accept(payload_: Variant, account_id_: Variant) -> RefCounted:
	var result = new()
	result.accepted = true
	result.payload = payload_
	result.account_id = account_id_
	return result

static func reject(reason_: Variant) -> RefCounted:
	var result = new()
	result.accepted = false
	result.reason = reason_
	return result
