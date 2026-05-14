# AlephVault.MMO.Storage

`AlephVault.MMO.Storage` is a Godot client for the AlephVault standard HTTP
storage protocol. It mirrors the shape of the Unity remote-storage package:
a root object creates resource handles, resource handles perform CRUD and
custom method calls, and every operation returns a `Result` instead of throwing
storage-level errors.

The package is exposed through the global class:

```gdscript
AlephVault__MMO__Storage
```

## When To Use It

Use this package when a Godot MMO client or tool needs to read and write data
through a remote HTTP storage service. Typical resources are accounts, player
profiles, inventories, worlds, characters, settings, or server-side game state.

The client assumes the server speaks the AlephVault standard HTTP storage
protocol. A compatible backend is usually structured around:

- Simple resources: one object at a fixed endpoint, such as `/account`.
- List resources: a collection of objects, such as `/characters`.
- Item endpoints: one object inside a list resource, such as `/characters/abc`.
- Custom view methods: read-only methods under `~method`.
- Custom operation methods: write-capable methods under `~method`.

For the backend-side reference, see:
https://github.com/AlephVault/golang-standard-http-mongodb-storage

## Package Layout

The package index exposes the main types:

```gdscript
const Storage = AlephVault__MMO__Storage

Storage.Types.Result
Storage.Types.ResultCode

Storage.StandardHttp.Authorization
Storage.StandardHttp.Cursor
Storage.StandardHttp.Root
Storage.StandardHttp.SimpleResource
Storage.StandardHttp.ListResource
Storage.StandardHttp.Engine
```

The nested namespaces also exist:

```gdscript
Storage.Types.Results.Result
Storage.StandardHttp.Types.Root
Storage.StandardHttp.Implementation.Engine
```

Prefer the shorter direct names unless you need the folder-shaped namespace.

## Quick Start

This example assumes `Account` is a GDScript class that can be instantiated
with `Account.new()`.

```gdscript
const Storage = AlephVault__MMO__Storage

func load_account(token: String) -> void:
	var auth = Storage.StandardHttp.Authorization.new("Bearer", token)
	var root = Storage.StandardHttp.Root.new("https://storage.example.test", auth)
	var account = root.get_simple("account", Account)

	var result = await account.read()
	if result.code == Storage.Types.ResultCode.Ok:
		print(result.element)
	else:
		push_warning("Could not read account: %s" % result.code)
```

## Core Concepts

### Authorization

`Authorization` is a small data object with two fields:

```gdscript
var auth = Storage.StandardHttp.Authorization.new("Bearer", token)
```

The HTTP client sends it as:

```http
Authorization: Bearer <token>
```

Use whichever scheme your server expects, such as `Bearer`, `Basic`, or a
custom scheme.

### Root

`Root` stores the base endpoint and authorization header:

```gdscript
var root = Storage.StandardHttp.Root.new("https://storage.example.test", auth)
```

The root trims a trailing slash, so these are equivalent:

```gdscript
Storage.StandardHttp.Root.new("https://storage.example.test", auth)
Storage.StandardHttp.Root.new("https://storage.example.test/", auth)
```

From the root, create resource handles:

```gdscript
var account = root.get_simple("account", Account)
var characters = root.get_list("characters", CharacterSummary)
```

### Results

All resource methods return `Storage.Types.Result`.

Important fields:

```gdscript
result.code
result.element
result.elements
result.created_id
result.validation_errors
result.request_error_code
```

Check `result.code` before reading successful data:

```gdscript
match result.code:
	Storage.Types.ResultCode.Ok:
		print(result.element)
	Storage.Types.ResultCode.Created:
		print(result.created_id)
	Storage.Types.ResultCode.ValidationError:
		print(result.validation_errors)
	_:
		push_warning("Storage error: %s" % result.code)
```

Common success codes:

- `ResultCode.Ok`: read, update, replace, delete, view, and operation calls
  completed.
- `ResultCode.Created`: create completed and may include `created_id`.

Common failure codes:

- `Unauthorized`: the authorization header is missing or rejected.
- `Forbidden`: authenticated, but not allowed.
- `DoesNotExist`: resource or item not found.
- `Unsupported`: endpoint does not support the HTTP method.
- `AlreadyExists`: simple resource already exists on create.
- `ValidationError`: request body failed schema validation.
- `DuplicateKey`: a unique key conflict occurred.
- `InUse`: item cannot be deleted because something references it.
- `FormatError`: request or response JSON shape is not what the client expects.
- `BadRequest`: server returned a custom 400 code.
- `Unreachable`, `Timeout`, `ServiceUnavailable`, `InternalError`: transport or
  server failures.

## Remote API Contract

This is the HTTP protocol shape expected by the client.

### Headers

All requests include:

```http
Authorization: <scheme> <value>
```

Requests with JSON bodies also include:

```http
Content-Type: application/json
```

Responses are expected to be JSON when the operation returns data or structured
errors.

### Simple Resource Endpoints

For a simple resource named `account`, the client uses:

```http
POST   /account
GET    /account
PATCH  /account
PUT    /account
DELETE /account
GET    /account/~<method>?arg=value
POST   /account/~<method>?arg=value
```

Expected behavior:

- `POST /account`: creates the only account object. The body is the object to
  create. The server may return `{"id":"..."}`.
- `GET /account`: returns the account object.
- `PATCH /account`: applies a MongoDB-style patch, such as
  `{"$set":{"display_name":"Ana"}}`.
- `PUT /account`: replaces the full account object.
- `DELETE /account`: deletes the account object.
- `GET /account/~summary`: calls a read-only custom method.
- `POST /account/~grant_item`: calls a write-capable custom method.

### List Resource Endpoints

For a list resource named `characters`, the client uses:

```http
GET    /characters?offset=0&limit=50
POST   /characters
GET    /characters/<id>
PATCH  /characters/<id>
PUT    /characters/<id>
DELETE /characters/<id>
GET    /characters/~<method>?arg=value
POST   /characters/~<method>?arg=value
GET    /characters/<id>/~<method>?arg=value
POST   /characters/<id>/~<method>?arg=value
```

Expected behavior:

- `GET /characters?offset=0&limit=50`: returns a JSON array of list entries.
- `POST /characters`: creates a new item. The server may return `{"id":"..."}`.
- `GET /characters/<id>`: returns one item.
- `PATCH /characters/<id>`: applies a MongoDB-style patch to one item.
- `PUT /characters/<id>`: replaces one item.
- `DELETE /characters/<id>`: deletes one item.
- `GET /characters/~search`: calls a read-only custom method over the whole
  list.
- `POST /characters/~bulk_grant`: calls a write-capable custom method over the
  whole list.
- `GET /characters/<id>/~stats`: calls a read-only custom method over one item.
- `POST /characters/<id>/~equip`: calls a write-capable custom method over one
  item.

### Error Response Bodies

The client maps HTTP statuses into `ResultCode` values.

For `400 Bad Request`, the server should return:

```json
{
  "code": "schema:invalid",
  "errors": {
    "display_name": "is required"
  }
}
```

Known `400` codes:

- `authorization:missing-header`: maps to `Unauthorized`.
- `authorization:bad-scheme`: maps to `Unauthorized`.
- `schema:invalid`: maps to `ValidationError` and copies `errors`.
- `format:unexpected`: maps to `FormatError`.
- anything else: maps to `BadRequest` and copies the code into
  `request_error_code`.

For `409 Conflict`, the server should return:

```json
{
  "code": "duplicate-key"
}
```

Known `409` codes:

- `already-exists`: maps to `AlreadyExists`.
- `in-use`: maps to `InUse`.
- `duplicate-key`: maps to `DuplicateKey`.
- anything else: maps to `Conflict`.

Other status mappings:

- `401`: `Unauthorized`
- `403`: `Forbidden`
- `404` or `410`: `DoesNotExist`
- `405`: `Unsupported`
- `406` or `415`: `FormatError`
- `500`: `InternalError`
- `502`: `Unreachable`
- `503`: `ServiceUnavailable`
- `504`: `Timeout`
- other `4xx`: `ClientError`
- other `5xx`: `ServerError`

## Comprehensive Example

The following example uses one simple resource and one list resource:

- `account`: the current user's account.
- `characters`: the current user's characters.

### Example Remote API

Assume the server exposes:

```http
GET /account
```

Response:

```json
{
  "id": "acc_001",
  "display_name": "Ana",
  "wallet": {
    "gold": 100,
    "gems": 4
  }
}
```

```http
GET /characters?offset=0&limit=10
```

Response:

```json
[
  {
    "id": "char_001",
    "name": "Mara",
    "level": 12,
    "stats": {
      "hp": 140,
      "mp": 25
    },
    "inventory": [
      {
        "item_id": "potion",
        "amount": 3
      }
    ]
  }
]
```

```http
POST /characters
```

Request:

```json
{
  "name": "Lio",
  "class": "mage"
}
```

Response:

```json
{
  "id": "char_002"
}
```

```http
POST /characters/char_001/~equip?slot=weapon
```

Request:

```json
{
  "item_id": "iron_sword"
}
```

Response:

```json
{
  "equipped": true,
  "power": 18
}
```

### Example Data Classes

Create simple data scripts for typed deserialization.

`res://storage/types/wallet.gd`

```gdscript
extends RefCounted
class_name Wallet

var gold: int = 0
var gems: int = 0
```

`res://storage/types/account.gd`

```gdscript
extends RefCounted
class_name Account

var id: String = ""
var display_name: String = ""
var wallet: Wallet = null
```

`res://storage/types/character_stats.gd`

```gdscript
extends RefCounted
class_name CharacterStats

var hp: int = 0
var mp: int = 0
```

`res://storage/types/inventory_item.gd`

```gdscript
extends RefCounted
class_name InventoryItem

var item_id: String = ""
var amount: int = 0
```

`res://storage/types/character_summary.gd`

```gdscript
extends RefCounted
class_name CharacterSummary

var id: String = ""
var name: String = ""
var level: int = 0
var stats: CharacterStats = null
var inventory: Array[InventoryItem] = []
```

`res://storage/types/equip_result.gd`

```gdscript
extends RefCounted
class_name EquipResult

var equipped: bool = false
var power: int = 0
```

### Example Client Code

```gdscript
extends Node

const Storage = AlephVault__MMO__Storage

var root: Storage.StandardHttp.Root

func _ready() -> void:
	var token = "example-token"
	var auth = Storage.StandardHttp.Authorization.new("Bearer", token)
	root = Storage.StandardHttp.Root.new("https://storage.example.test", auth)

	await load_account()
	await load_characters()
	await create_character()
	await equip_weapon("char_001", "iron_sword")

func load_account() -> void:
	var account_resource = root.get_simple("account", Account)

	var result = await account_resource.read()
	if result.code != Storage.Types.ResultCode.Ok:
		_log_storage_error("load account", result)
		return

	var account: Account = result.element
	print("Account: %s, gold: %s" % [account.display_name, account.wallet.gold])

func load_characters() -> void:
	var characters = root.get_list("characters", CharacterSummary)
	var cursor = Storage.StandardHttp.Cursor.new(0, 10)

	var result = await characters.list(cursor)
	if result.code != Storage.Types.ResultCode.Ok:
		_log_storage_error("load characters", result)
		return

	for character: CharacterSummary in result.elements:
		print("%s level %s, hp %s" % [character.name, character.level, character.stats.hp])
		for item: InventoryItem in character.inventory:
			print("  %s x%s" % [item.item_id, item.amount])

func create_character() -> void:
	var characters = root.get_list("characters", CharacterSummary)
	var body = {
		"name": "Lio",
		"class": "mage",
	}

	var result = await characters.create(body)
	if result.code != Storage.Types.ResultCode.Created:
		_log_storage_error("create character", result)
		return

	print("Created character id: %s" % result.created_id)

func equip_weapon(character_id: String, item_id: String) -> void:
	var characters = root.get_list("characters", CharacterSummary)
	var args = {"slot": "weapon"}
	var body = {"item_id": item_id}

	var result = await characters.item_operation_to(
		character_id, "equip", args, EquipResult, body
	)
	if result.code != Storage.Types.ResultCode.Ok:
		_log_storage_error("equip weapon", result)
		return

	var equip_result: EquipResult = result.element
	print("Equipped: %s, power: %s" % [equip_result.equipped, equip_result.power])

func _log_storage_error(action: String, result: Storage.Types.Result) -> void:
	match result.code:
		Storage.Types.ResultCode.ValidationError:
			push_warning("%s failed validation: %s" % [action, result.validation_errors])
		Storage.Types.ResultCode.BadRequest:
			push_warning("%s bad request: %s" % [action, result.request_error_code])
		_:
			push_warning("%s failed with code: %s" % [action, result.code])
```

## Raw JSON Methods

Use raw JSON methods when you want `Dictionary` or `Array` values instead of
typed instances.

Simple resource:

```gdscript
await account.read()
await account.view_to_json("summary", {})
await account.operation_to_json("rename", {}, {"display_name": "Ana"})
await account.view_to_json_array("history", {})
await account.operation_to_json_array("grant_many", {}, {"items": ["a", "b"]})
```

List resource:

```gdscript
await characters.list(Storage.StandardHttp.Cursor.new(0, 50))
await characters.read("char_001")
await characters.view_to_json("search", {"q": "ma"})
await characters.operation_to_json("bulk_grant", {}, {"gold": 10})
await characters.item_view_to_json("char_001", "stats", {})
await characters.item_operation_to_json("char_001", "equip", {"slot": "weapon"}, {"item_id": "sword"})
await characters.view_to_json_array("ranking", {})
await characters.item_view_to_json_array("char_001", "recent_events", {})
```

## Typed Methods

Use typed methods when you want JSON objects converted into GDScript instances.

Simple resource:

```gdscript
await account.read()
await account.view_to("summary", {}, AccountSummary)
await account.operation_to("rename", {}, Account, {"display_name": "Ana"})
```

List resource:

```gdscript
await characters.list(Storage.StandardHttp.Cursor.new(0, 50))
await characters.read("char_001")
await characters.view_to("search", {"q": "ma"}, SearchResult)
await characters.operation_to("bulk_grant", {}, BulkGrantResult, {"gold": 10})
await characters.item_view_to("char_001", "stats", {}, CharacterStats)
await characters.item_operation_to("char_001", "equip", {"slot": "weapon"}, EquipResult, {"item_id": "sword"})
```

Typed deserialization rules:

- The target script must be instantiable with `.new()`.
- The response must be a JSON object for `read`, `view_to`,
  `operation_to`, `item_view_to`, and `item_operation_to`.
- The response must be a JSON array of objects for `list`.
- JSON keys are matched to stored properties with the same name.
- Missing JSON keys leave the property's default value unchanged.
- Unknown JSON keys are ignored.
- Primitive fields are validated and converted where safe:
  - JSON integers/floats can populate `int` and `float`.
  - JSON strings can populate `String` and `StringName`.
  - JSON booleans populate `bool`.
- Nested object fields are recursively deserialized when the script type is
  discoverable through Godot property metadata, or when the field already has a
  default object instance with a script.
- Typed arrays are recursively deserialized when Godot exposes the element
  script or primitive element type in property metadata.
- If any nested field or array item fails to deserialize, the parent result
  returns `ResultCode.FormatError`.

## CRUD Reference

### Root

```gdscript
new(base_endpoint: String, authorization: Authorization)
get_simple(name: String, response_class: Script) -> SimpleResource
get_list(name: String, element_class: Script) -> ListResource
```

### SimpleResource

```gdscript
new(name: String, base_endpoint: String, authorization: Authorization, response_class: Script)
create(body: Variant) -> Result
read() -> Result
read_json() -> Result
update(changes: Dictionary) -> Result
replace(replacement: Variant) -> Result
delete() -> Result
view_to_json(method: String, args: Dictionary = {}) -> Result
operation_to_json(method: String, args: Dictionary = {}, body: Variant = null) -> Result
view_to_json_array(method: String, args: Dictionary = {}) -> Result
operation_to_json_array(method: String, args: Dictionary = {}, body: Variant = null) -> Result
view_to(method: String, args: Dictionary, response_class: Script) -> Result
operation_to(method: String, args: Dictionary, response_class: Script, body: Variant = null) -> Result
```

### ListResource

```gdscript
new(name: String, base_endpoint: String, authorization: Authorization, element_class: Script)
list(cursor: Cursor) -> Result
list_json(cursor: Cursor) -> Result
create(body: Variant) -> Result
read(id: String) -> Result
read_json(id: String) -> Result
update(id: String, changes: Dictionary) -> Result
replace(id: String, replacement: Variant) -> Result
delete(id: String) -> Result
view_to_json(method: String, args: Dictionary = {}) -> Result
operation_to_json(method: String, args: Dictionary = {}, body: Variant = null) -> Result
item_view_to_json(id: String, method: String, args: Dictionary = {}) -> Result
item_operation_to_json(id: String, method: String, args: Dictionary = {}, body: Variant = null) -> Result
view_to_json_array(method: String, args: Dictionary = {}) -> Result
operation_to_json_array(method: String, args: Dictionary = {}, body: Variant = null) -> Result
item_view_to_json_array(id: String, method: String, args: Dictionary = {}) -> Result
item_operation_to_json_array(id: String, method: String, args: Dictionary = {}, body: Variant = null) -> Result
view_to(method: String, args: Dictionary, response_class: Script) -> Result
operation_to(method: String, args: Dictionary, response_class: Script, body: Variant = null) -> Result
item_view_to(id: String, method: String, args: Dictionary, response_class: Script) -> Result
item_operation_to(id: String, method: String, args: Dictionary, response_class: Script, body: Variant = null) -> Result
```

## Notes

- The client strips query strings from resource endpoints before adding its own
  query arguments, matching the Unity package behavior.
- Custom method names are appended as `~method`; pass only the method name, not
  the tilde.
- Item ids are URL-encoded by the list resource.
- The client currently creates a temporary `HTTPRequest` node per operation and
  adds it to the scene tree root.
- This package handles storage protocol errors. Application-level validation
  and authorization rules still belong on the server.
