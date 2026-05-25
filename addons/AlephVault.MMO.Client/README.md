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

Useful members:

- `connections: AlephVault__MMO__Client.Connections`
- `protocols: AlephVault__MMO__Client.Protocols.Manager`
- `address: String`
- `port: int`
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
adds every unique default/dynamic scope scene resource path as spawnable, and
adds the spawner. Scope instances are created by the server and replicated to
the client through the spawner. Both nodes are removed when the protocol exits
the tree.

```gdscript
extends AlephVault__MMO__Client.Protocols.SpawningProtocol

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
