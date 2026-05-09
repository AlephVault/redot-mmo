extends RefCounted

# Authorization header data used by the standard HTTP storage client.
#
# The request engine sends this as:
# Authorization: <scheme> <value>
var scheme: String
var value: String

## Creates an authorization header value.
##
## Typical schemes are "Bearer" or "Basic", depending on the storage service.
func _init(scheme_: String = "", value_: String = "") -> void:
	scheme = scheme_
	value = value_
