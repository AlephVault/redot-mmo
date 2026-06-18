extends Object

## Authorization header data.
const Authorization = preload("./types/authorization.gd")
## Offset/limit cursor for list endpoints.
const Cursor = preload("./types/cursor.gd")
## Shared base class for resource handles.
const BaseResource = preload("./types/resource.gd")
## Handle for one-object resources.
const SimpleResource = preload("./types/simple_resource.gd")
## Handle for collection resources.
const ListResource = preload("./types/list_resource.gd")
## Entry point for creating resource handles.
const Root = preload("./types/root.gd")
## Low-level HTTP request engine.
const RequestEngine = preload("./implementation/engine.gd")
