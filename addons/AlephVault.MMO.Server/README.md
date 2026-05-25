# AlephVault.MMO.Server

Server-side Multiplayer API nodes for MMO-style projects.

This package exposes the global namespace `AlephVault__MMO__Server` and depends
on [AlephVault.MMO.Common](../AlephVault.MMO.Common/README.md).

Read the client package documentation for the mirrored client-side setup:
[AlephVault.MMO.Client](../AlephVault.MMO.Client/README.md).

## Mirrored Scene Structure

The server scene must mirror the client scene path for RPC synchronization.
The classes can differ, but the node names and hierarchy must match.

```text
Server scene:
MyGame (extends AlephVault__MMO__Server.Main)

Client scene:
MyGame (extends AlephVault__MMO__Client.Main)
```

In the editor, a server `Main` may also have direct child nodes whose scripts
extend `AlephVault__MMO__Server.Protocols.Protocol`:

```text
MyGame (extends AlephVault__MMO__Server.Main)
  InventoryProtocol
  CombatProtocol
```

Protocols are a mirrored MMO concept that will be explained later. When the
server enters the tree, those direct protocol children are collected, sorted by
their static dependencies, and moved under the generated `Protocols` node.

## Runtime Structure

When a server `Main` enters the tree, it creates:

```text
MyGame
  Protocols
    InventoryProtocol
    CombatProtocol
  Connections
    Connection_<peer_id>
      # Then, these appear for each connection:
      <ProtocolName>
        Commands
        Notifications
```

The server creates one connection node per connected peer. Protocol `Commands`
receive client RPCs. Protocol `Notifications` send server RPCs to the owning
client.

## Server Classes

A server `Main` subclass is optional. It is typically useful when you want to
hook signals such as `server_started`, `server_stopped`, `client_entered`,
`client_left`, or `scope_changed`, or when you need custom `_process`
input/orchestration:

```gdscript
extends AlephVault__MMO__Server.Main
```

Connections use the built-in `AlephVault__MMO__Server.Connection` class.

Protocols are explained later.

## Launching

Use the `Main` node in the server scene:

```gdscript
var err := my_server.launch(6777, 32)
var stopped := my_server.stop()
```

Useful members:

- `connections: AlephVault__MMO__Server.Connections`
- `protocols: AlephVault__MMO__Server.Protocols.Manager`
- `address: String`
- `port: int`
- `signal server_started`
- `signal server_stopped`
- `signal client_entered(id: int)`
- `signal client_left(id: int)`
- `signal scope_changed(connection_id: int, current_scope_id: int, scope_id: int)`

## Scope Management

Scope ids come from `AlephVault__MMO__Common.Scopes`.

```gdscript
const Scopes = AlephVault__MMO__Common.Scopes

var scope_id := Scopes.make_fq_default_scope_id(0)
var connections: AlephVault__MMO__Server.Connections = my_server.connections

connections.set_connection_scope(peer_id, scope_id)
connections.scope_iterate(scope_id, func(connection: AlephVault__MMO__Server.Connection):
	print("Connection in scope: ", connection.id)
)
```

`Connections` provides:

- `get_connections_in_scope(scope_id: int) -> Array[int]`
- `get_connection_scope(connection_id: int) -> int`
- `set_connection_scope(connection_id: int, scope_id: int)`
- `has_connection(connection_id: int) -> bool`
- `get_connections() -> Array[int]`
- `get_connection_node(id: int) -> AlephVault__MMO__Server.Connection`
- `scope_iterate(scope_id: int, method: Callable)`
- `has_scope(scope_id: int) -> bool`

The chat sample is in `addons/AlephVault.MMO.Samples`.

## Protocols

Protocols are bundles of logic and their related messages. They provide pre-implemented
behavior to be used later and are the actual, essential, part of the MMO. The logic is
typically implemented on the server, and a custom local tracking might be implemented
on the client. However, both parts (client and server) are mandatory.

Protocol support is exposed through the `AlephVault__MMO__Server.Protocols`
namespace:

- `AlephVault__MMO__Server.Protocols.Manager`: the generated runtime container
  node under `Main`.
- `AlephVault__MMO__Server.Protocols.Protocol`: a protocol node placed directly under
  `Main` in the editor. Its static `dependencies` property controls protocol
  ordering.
- `AlephVault__MMO__Server.Protocols.SpawningProtocol`: an abstract protocol base
  for protocols that need their own spawn root and `MultiplayerSpawner`.
- `AlephVault__MMO__Server.Protocols.Commands`: routes protocol commands sent
  from the client to the server.
- `AlephVault__MMO__Server.Protocols.Notifications`: routes protocol
  notifications and responses sent from the server to the client.

### Spawning Protocol

`AlephVault__MMO__Server.Protocols.SpawningProtocol` is an opt-in abstract base
for server protocols that own spawned nodes. `Main` does not create a shared
`World` or `MultiplayerSpawner`; protocols that need spawning should inherit
from this class and provide those nodes themselves.

When a spawning protocol is moved under the generated `Protocols` node, it calls
`_create_world()`. If that returns a node, the protocol adds it as a direct child
named `World`, caches `_define_default_scopes()` and `_define_dynamic_scopes()`,
creates a sibling `MultiplayerSpawner` child, calls `_setup_spawner(spawner)`,
adds every unique default/dynamic scope scene resource path as spawnable, and
adds the spawner. Both nodes are removed when the protocol exits the tree.

Default scopes are created under `World` immediately. Their ids are
`AlephVault__MMO__Common.Scopes.make_fq_default_scope_id(index)`. Each default
scope scene root must have a child named `MultiplayerSynchronizer`; scenes that
do not are instantiated only long enough to be rejected. Accepted scope
synchronizers are configured as private, with `root_path = ".."` and
`VISIBILITY_PROCESS_NONE`. The protocol updates their visibility when server
connection scopes change.

Dynamic scope templates are not created on startup. Use
`create_dynamic_scope(template_index, id)` to create an instance with
`make_fq_dynamic_scope_id(id)`, and `destroy_dynamic_scope(id)` to remove it
when no connection is currently in that scope.

```gdscript
extends AlephVault__MMO__Server.Protocols.SpawningProtocol

@export var room_scene: PackedScene

func _create_world() -> Node:
	return Node.new()

func _setup_spawner(s: MultiplayerSpawner) -> void:
	s.spawn_path = get_node("World").get_path()

func _define_dynamic_scopes() -> Array[PackedScene]:
	return [room_scene]
```

### Commands and Notifications

For `Protocols.Commands` and `Protocols.Notifications` subclasses, it is highly
recommended that all RPC methods are declared as:

```gdscript
@rpc("authority", "call_remote", "reliable")
```

Server protocols can override `_create_commands_node()` and
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

Server protocol nodes provide helpers for common lookups:

- `get_protocol(protocol_class: Script)`: gets another installed protocol.
- `get_connection(id: int)`: gets the connection for a peer id.
- `get_notifications(id: int)`: gets this protocol's `Notifications` node for
  that connection.
- `notify(id: int, method: String[, arguments: Array])`: directly notifies the
  connection about a specific event. Typically, the id will match the one for
  the connection.

Server commands nodes provide:

- `connection_node()`: gets the server connection this command node belongs to.
- `protocol_node()`: gets the central protocol instance that owns the command
  node.

Server notifications nodes provide:

- `notify(id: int, method: String[, arguments: Array])`: directly notifies the
  connection about a specific event. Typically, the id will match the one for
  the connection.

### Separation of Concerns

Ideally, the Protocol should implement the logic through regular method calls,
and a single object should handle the core logic.

The flow would typically be:

```
# To act on a specific client.
server code -> protocol method -> get client connection -> protocol notification

# To react on a client command.
protocol command -> protocol method for that client -> server code
```

With this in mind, the implementation of a Protocols.Commands class should only
invoke protocol methods (a minimalistic implementation), and the implementation
of a Protocols.Notifications class should be also minimalistic (just the stub).

### Server Hooks

After a server is launched successfully, each protocol receives a
`server_started()` hook in dependency order. After a server is stopped
successfully, each protocol receives `server_stopped()` in the same order.

When a client connection is established, each protocol receives
`client_entered(id)` in dependency order after the connection node exists. When
a client connection is closed, each protocol receives `client_left(id)` in the
same order before the connection node is removed.

They're defined like:

```gdscript
async server_started():
    ...

async server_stopped():
    ...

async client_entered(id: int):
    ...

async client_left(id: int):
    ...
```

## Authentication

The package includes a reusable simple authentication protocol under
`AlephVault__MMO__Server.Protocols.Authentication`.

Use `AlephVault__MMO__Server.Protocols.Authentication.Protocol` when this server
authenticates clients and owns their session lifecycle. Concrete implementations
override:

```gdscript
func _authenticate(connection_id: int, method: String, payload: Variant) -> Dictionary:
	return AlephVault__MMO__Common.Protocols.Authentication.LoginResult.reject()

func _find_account(account_id: Variant) -> Variant:
	return account_id

func _if_account_already_logged_in() -> int:
	return AlephVault__MMO__Common.Protocols.Authentication.AccountAlreadyLoggedManagementMode.REJECT
```

`_authenticate` returns `LoginResult.accept(ok_payload, account_id)` or
`LoginResult.reject(failure_payload)`. The base protocol owns generic
login/logout RPC routing, session maps by connection and account, duplicate
account policy, logout, kicks, session data helpers, and login-required wrappers.

It emits `session_starting(connection_id, account_data)`,
`session_terminating(connection_id, reason)`, and
`session_error(connection_id, stage, error)`. Concrete credential payloads, such
as username/password strings, belong in `AlephVault.MMO.Samples` or game-specific
packages, not in this server package.

The authentication command node only routes RPC commands into public methods on
the central authentication protocol. The base protocol exposes these methods to
other server protocols:

- `kick(account_id: Variant, reason: Variant = null) -> void`
- `kick_connection(connection_id: int, reason: Variant = null) -> void`
- `login_required(connection_id: int, action: Callable, allowed: Callable = Callable()) -> Variant`
- `logout_required(connection_id: int, action: Callable) -> Variant`
- `session_exists(connection_id: int) -> bool`
- `get_session_account_id(connection_id: int) -> Variant`
- `set_session_data(connection_id: int, key: String, value: Variant) -> void`
- `get_session_data(connection_id: int, key: String) -> Variant`
- `try_get_session_data(connection_id: int, key: String, default_value: Variant = null) -> Variant`
- `remove_session_data(connection_id: int, key: String) -> bool`
- `clear_session_data(connection_id: int) -> void`
- `session_contains_key(connection_id: int, key: String) -> bool`

The `handle_*` methods are RPC adapter entrypoints used by the authentication
command node, and are not part of the protocol surface other protocols should
call directly.
