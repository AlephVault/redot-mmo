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
extend `AlephVault__MMO__Server.Protocol`:

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
  World
  MultiplayerSpawner
  Connections
    Connection_<peer_id>
      <ProtocolName>
        Commands
        Notifications
```

The server creates one connection node per connected peer. Protocol `Commands`
receive client RPCs. Protocol `Notifications` send server RPCs to the owning
client.

## Defining Server Classes

Create a connection subclass when the server needs custom connection state:

```gdscript
extends AlephVault__MMO__Server.Connection
```

Then define a server main subclass:

```gdscript
extends AlephVault__MMO__Server.Main

const Connection = preload("./my-connection.gd")

func connection_class() -> Script:
	return Connection
```

## Launching

Use the `Main` subclass in the server scene:

```gdscript
var err := my_server.launch(6777, 32)
var stopped := my_server.stop()
```

Useful members:

- `connections: AlephVault__MMO__Server.Connections`
- `world: AlephVault__MMO__Server.World`
- `protocols: AlephVault__MMO__Server.Protocols`
- `spawner: MultiplayerSpawner`
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

Protocol support currently exposes three server-side base classes:

- `AlephVault__MMO__Server.Protocol`: a protocol node placed directly under
  `Main` in the editor. Its static `dependencies` property controls protocol
  ordering.
- `AlephVault__MMO__Server.ProtocolCommands`: routes protocol commands sent
  from the client to the server.
- `AlephVault__MMO__Server.ProtocolNotifications`: routes protocol
  notifications and responses sent from the server to the client.

### Commands and Notifications

For `ProtocolCommands` and `ProtocolNotifications` subclasses, it is highly
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
