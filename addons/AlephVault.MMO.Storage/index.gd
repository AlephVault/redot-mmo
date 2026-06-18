extends Object

class_name AlephVault__MMO__Storage

## Public namespace for storage result types.
class Types:
	## Result code enum and constants.
	const ResultCode = preload("./types/results/result_code.gd")
	## Result object returned by resource operations.
	const Result = preload("./types/results/result.gd")

	## Compatibility namespace matching the result-type folder.
	class Results:
		## Result code enum and constants.
		const ResultCode = preload("./types/results/result_code.gd")
		## Result object returned by resource operations.
		const Result = preload("./types/results/result.gd")

## Public namespace for the standard HTTP storage implementation.
class StandardHttp:
	## Authorization header data.
	const Authorization = preload("./standard_http/types/authorization.gd")
	## Offset/limit cursor for list endpoints.
	const Cursor = preload("./standard_http/types/cursor.gd")
	## Shared base class for resource handles.
	const BaseResource = preload("./standard_http/types/resource.gd")
	## Handle for one-object resources.
	const SimpleResource = preload("./standard_http/types/simple_resource.gd")
	## Handle for collection resources.
	const ListResource = preload("./standard_http/types/list_resource.gd")
	## Entry point for creating resource handles.
	const Root = preload("./standard_http/types/root.gd")
	## Low-level HTTP request engine.
	const RequestEngine = preload("./standard_http/implementation/engine.gd")

	## Compatibility namespace matching the standard_http/types folder.
	class Types:
		## Authorization header data.
		const Authorization = preload("./standard_http/types/authorization.gd")
		## Offset/limit cursor for list endpoints.
		const Cursor = preload("./standard_http/types/cursor.gd")
