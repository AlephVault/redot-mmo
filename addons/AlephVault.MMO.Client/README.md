# AlephVault.MMO.Client

Client-side Multiplayer API nodes for MMO-style projects.

This package exposes the global namespace `AlephVault__MMO__Client` and depends
on [AlephVault.MMO.Common](../AlephVault.MMO.Common/README.md).

Read the server package documentation for the mirrored server-side setup:
[AlephVault.MMO.Server](../AlephVault.MMO.Server/README.md).

## Mirrored Scene Structure

Godot's Multiplayer API requires RPC peers to have matching node paths. Your
client scene and server scene may live in different files, but the relevant MMO
nodes must have the same names and hierarchy.

Example:

```text
Client scene:
MyGame (extends AlephVault__MMO__Client.Main)

Server scene:
MyGame (extends AlephVault__MMO__Server.Main)
```

Both peers then address the main node as `/root/MyGame`. You can use
`AlephVault__MMO__Client.Main` directly or use a subclass, but the matching
client/server nodes must keep matching paths.

In the editor, a client `Main` may also have direct child nodes whose scripts
extend `AlephVault__MMO__Client.Protocols.Protocol`:

```text
MyGame (extends AlephVault__MMO__Client.Main)
  InventoryProtocol
  CombatProtocol
```

Protocols are a mirrored MMO concept that will be explained later. When the
client enters the tree, those direct protocol children are collected, sorted by
their static dependencies, and moved under the generated `Protocols` node.

## Runtime Structure

When a client `Main` enters the tree, it creates:

```text
MyGame
  Protocols
    InventoryProtocol
    CombatProtocol
  Connections
    # Then, these appear for each connection:
    Connection_<peer_id>
      <ProtocolName>
        Commands
        Notifications
```

The client only mirrors its own connection node. Protocol `Commands` are owned
by the client and are used to call server RPCs. Protocol `Notifications` are
owned by the server and receive server RPCs.

## Client Classes

A client `Main` subclass is optional. It is typically useful when you want to
hook signals such as `client_started`, `client_stopped`, `client_failed`, or
`scope_changed`, or when you need custom `_process` input/UI orchestration:

```gdscript
extends AlephVault__MMO__Client.Main
```

Connections use the built-in `AlephVault__MMO__Client.Connection` class.

Protocols are explained later.

## Connecting

Use the `Main` node in the client scene:

```gdscript
var err := my_client.join_server("127.0.0.1", 6777)
var stopped := my_client.leave_server()
```

Set `peer_type` to choose the multiplayer peer implementation before calling
`join_server()`:

```gdscript
my_client.peer_type = AlephVault__MMO__Common.Setup.PeerType.WEBSOCKETS
my_client.ws_secure = false
my_client.ws_path = "/"
var err := my_client.join_server("127.0.0.1", 6777)
```

Useful members:

- `connections: AlephVault__MMO__Client.Connections`
- `protocols: AlephVault__MMO__Client.Protocols.Manager`
- `address: String`
- `port: int`
- `peer_type: AlephVault__MMO__Common.Setup.PeerType`
- `enet_channel_count: int`
- `enet_in_bandwidth: int`
- `enet_out_bandwidth: int`
- `enet_local_port: int`
- `ws_secure: bool`
- `ws_path: String`
- `ws_supported_protocols: PackedStringArray`
- `ws_handshake_headers: PackedStringArray`
- `ws_handshake_timeout: float`
- `ws_inbound_buffer_size: int`
- `ws_outbound_buffer_size: int`
- `ws_max_queued_packets: int`
- `signal client_started`
- `signal client_stopped`
- `signal client_failed`
- `signal scope_changed(current_scope_id: int, scope_id: int)`

Use `connections.get_connection_node()` to access the current client connection.

## Protocols

Protocols are bundles of logic and their related messages. They provide pre-implemented
behavior to be used later and are the actual, essential, part of the MMO. The logic is
typically implemented on the server, and a custom local tracking might be implemented
on the client. However, both parts (client and server) are mandatory.

Protocol support is exposed through the `AlephVault__MMO__Client.Protocols`
namespace:

- `AlephVault__MMO__Client.Protocols.Manager`: the generated runtime container
  node under `Main`.
- `AlephVault__MMO__Client.Protocols.Protocol`: a protocol node placed directly under
  `Main` in the editor. Its static `dependencies` property controls protocol
  ordering.
- `AlephVault__MMO__Client.Protocols.SpawningProtocol`: an abstract protocol base
  for protocols that need their own spawn root and `MultiplayerSpawner`.
- `AlephVault__MMO__Client.Protocols.Commands`: routes protocol commands sent
  from the client to the server.
- `AlephVault__MMO__Client.Protocols.Notifications`: routes protocol
  notifications and responses sent from the server to the client.

### Spawning Protocol

`AlephVault__MMO__Client.Protocols.SpawningProtocol` is an opt-in abstract base
for client protocols that own spawned nodes. `Main` does not create a shared
`World` or `MultiplayerSpawner`; protocols that need spawning should inherit
from this class and provide those nodes themselves.

When a spawning protocol is moved under the generated `Protocols` node, it calls
`_create_world()`. If that returns a node, the protocol adds it as a direct child
named `World`, caches `_define_default_scopes()` and `_define_dynamic_scopes()`,
creates a sibling `MultiplayerSpawner` child, calls `_setup_spawner(spawner)`,
wraps any `spawner.spawn_function` configured there, connects spawner signals,
and adds the spawner. Scope instances are created explicitly by the server with
`MultiplayerSpawner.spawn(data)` and replicated to the client through the
spawner.

The wrapped spawn function receives a dictionary with `scene_index`,
`fq_scope_id`, `scope_type`, `scope_id`, `dynamic_scope_template_index`, and
`name`. `scene_index` is the index in the concatenated scope scene list:
`_define_default_scopes()` followed by `_define_dynamic_scopes()`. If
`_setup_spawner()` assigned a custom `spawn_function`, that function is invoked
first and must return a node that is not inside the scene tree. Otherwise, the
base implementation instantiates the scene at `scene_index`. The protocol then
sets the root name and calls `_setup_scope(scope)` before the spawner inserts the
node, so client-side setup can add synchronizers and support nodes before initial
replication can use them.

Replicated default scope root nodes are named `Scope<index>`, and replicated
dynamic scope root nodes are named `DynScope<id>`. The latest replicated scope
root is exposed as `active_scope`. It is updated from the
`MultiplayerSpawner.spawned` and `MultiplayerSpawner.despawned` signals: when a
scope is spawned, `active_scope` becomes that node; when that same scope is
despawned, `active_scope` becomes `null`. Both nodes are removed when the
protocol exits the tree.

Custom client logic can connect `active_scope_changed(current_scope, scope)`, or
override `_active_scope_set(scope)` and `_active_scope_unset(scope)`.

```gdscript
extends AlephVault__MMO__Client.Protocols.SpawningProtocol

@export var room_scene: PackedScene

func _create_world() -> Node:
	return Node.new()

func _setup_spawner(s: MultiplayerSpawner) -> void:
	s.spawn_path = get_node("World").get_path()
	s.spawn_function = func(data: Dictionary) -> Node:
		var scenes := _define_default_scopes() + _define_dynamic_scopes()
		var room := scenes[data["scene_index"]].instantiate()
		var synchronizer := MultiplayerSynchronizer.new()
		synchronizer.name = "MultiplayerSynchronizer"
		room.add_child(synchronizer)
		return room

func _define_dynamic_scopes() -> Array[PackedScene]:
	return [room_scene]

func _active_scope_set(scope: Node) -> void:
	print("Scope spawned: ", scope.name)

func _active_scope_unset(scope: Node) -> void:
	print("Scope despawned: ", scope.name)
```

### Commands and Notifications

For `Protocols.Commands` and `Protocols.Notifications` subclasses, it is highly
recommended that all RPC methods are declared as:

```gdscript
@rpc("authority", "call_remote", "reliable")
```

Client protocols can override `_create_commands_node()` and
`_create_notifications_node()` to provide protocol-specific RPC nodes. When a
protocol is installed on a connection, it creates this hierarchy under that
connection:

```text
Connection_<peer_id>
  <ProtocolName>
    Commands
    Notifications
```

`Commands` is created by `_create_commands_node()` and `Notifications` is
created by `_create_notifications_node()`. The installer renames those nodes to
the stable RPC path names shown above. The `Protocols` node installs every
protocol under each connection and assigns authorities: `Commands` to the
connection peer id and `Notifications` to peer `1`.

Client protocol nodes provide helpers for common lookups:

- `get_protocol(protocol_class: Script)`: gets another installed protocol.
- `get_connection()`: gets the current client connection, if connected.
- `get_commands()`: gets this protocol's `Commands` node for the current
  connection.
- `command(method: String[, arguments: Array])`: directly sends a specific command
  to the server.

Client commands nodes provide:

- `command(method: String[, arguments: Array])`: directly sends a specific command
  to the server.

Client notifications nodes provide:

- `connection_node()`: gets the current client connection.
- `protocol_node()`: gets the central protocol instance that owns the
  notification node.

### Separation of Concerns

Ideally, the Protocol should implement the logic through regular method calls,
and a single object should handle the core logic.

The flow would typically be:

```
# To perform an action.
user code -> protocol method -> get client connection -> protocol command

# To react to the server.
protocol notification -> protocol method -> user code
```

With this in mind, the implementation of a Protocols.Commands class should be
minimalistic, and the implementation of a Protocols.Notifications class should
only invoke protocol methods (also a minimalistic implementation).

### Client Hooks

After the client connects to a server successfully, each protocol receives a
`client_started()` hook in dependency order. After the client disconnects from
the server, each protocol receives `client_stopped()` in the same order.

They're defined like:

```gdscript
async client_started():
    ...

async client_stopped():
    ...
```

## Authentication

The package includes a reusable simple authentication protocol under
`AlephVault__MMO__Client.Protocols.Authentication`.

Use `AlephVault__MMO__Client.Protocols.Authentication.Protocol` when the server
owns authentication and session state. The base protocol sends `login(method,
payload)` and `logout()` requests, tracks `logged_in`, and emits:

- `login_ok(payload)`
- `login_failed(payload)`
- `kicked(payload)`
- `logged_out`
- `not_logged_in`
- `account_already_in_use`
- `already_logged_in`
- `forbidden`

The `method` string identifies the login mechanism and `payload` is an arbitrary
Variant defined by the concrete application or sample. This package deliberately
does not define username/password messages; those belong in
`AlephVault.MMO.Samples` or in a game package.

The authentication notification node only routes RPC notifications into public
methods on the central authentication protocol. Application code should interact
with the protocol through `login()`, `logout()`, `logged_in`, and the signals
listed above.

### Simple Authentication Profile

`AlephVault__MMO__Client.Protocols.Authentication.Simple.Protocol` extends the
base client authentication protocol with profile-management commands and
notifications.

Client code can call:

- `list_profiles()`: asks the server to refresh the current account's profile
  previews.
- `select_profile(profile_id)`: asks the server to open a profile.
- `close_profile()`: asks the server to close the currently selected profile.

The server only accepts `list_profiles()` and `select_profile()` while the
connection is logged in and in `SCOPE_ACCOUNT_DASHBOARD`. `close_profile()` is
accepted while logged in, but the server reports profile-specific errors when
the account is mono-profile or no profile is currently selected.

The protocol emits:

- `profiles_list(list)`: profile previews available for selection.
- `profile_invalid(reason)`: the requested profile id is invalid.
- `profile_unavailable(reason)`: the requested profile exists but cannot be
  opened.
- `profile_selected(profile_id, profile)`: a profile was opened. `profile` is
  the server-defined client-facing view.
- `profile_closed(reason)`: the selected profile was closed or stopped. `null`
  means a graceful close.
- `profile_not_selected(reason)`: close was requested without an open profile.
- `profile_not_closeable(reason)`: close was requested for a session that cannot
  close profiles, such as a mono-profile account.
