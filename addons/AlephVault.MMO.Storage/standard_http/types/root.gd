extends RefCounted

const Authorization = AlephVault__MMO__Storage.StandardHttp.Authorization
const SimpleResource = AlephVault__MMO__Storage.StandardHttp.SimpleResource
const ListResource = AlephVault__MMO__Storage.StandardHttp.ListResource

# Entry point for a standard HTTP storage service.
#
# A root stores the base endpoint and authorization header, then creates
# typed handles for simple and list resources under that endpoint.
var base_endpoint: String
var authorization: Authorization

## Creates a root over a base endpoint.
##
## The trailing slash in the endpoint is ignored. The authorization is required.
func _init(
	base_endpoint_: String = "",
	authorization_: Authorization = null
) -> void:
	assert(authorization_ != null, "An authorization header is required")
	base_endpoint = base_endpoint_.trim_suffix("/")
	authorization = authorization_

## Returns a handle to a simple resource at "<base_endpoint>/<name>".
##
## Simple resources represent a single object that can be created, read,
## patched, replaced, deleted, and queried through custom methods.
func get_simple(name: String) -> SimpleResource:
	return SimpleResource.new(name, base_endpoint, authorization)

## Returns a handle to a list resource at "<base_endpoint>/<name>".
##
## List resources represent collections where each item has a string id.
func get_list(name: String) -> ListResource:
	return ListResource.new(name, base_endpoint, authorization)
