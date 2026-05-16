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

## Runtime Structure

When a server `Main` enters the tree, it creates:

```text
MyGame
  World
  Connections
    Connection_<peer_id>
      Commands
      Notifications
  MultiplayerSpawner
```

The server creates one connection node per connected peer. `Commands` receives
client RPCs. `Notifications` sends server RPCs to the owning client.

## Defining Server Classes

Create a connection subclass and return command and notification nodes:

```gdscript
extends AlephVault__MMO__Server.Connection

const Commands = preload("./my-connection-commands.gd")
const Notifications = preload("./my-connection-notifications.gd")

func _make_commands_node() -> AlephVault__MMO__Server.ConnectionCommands:
	return Commands.new()

func _make_notifications_node() -> AlephVault__MMO__Server.ConnectionNotifications:
	return Notifications.new()
```

Commands implement the RPC methods sent by the client:

```gdscript
extends AlephVault__MMO__Server.ConnectionCommands

@rpc("authority", "call_remote", "reliable")
func ping(message: String):
	connection.notify_owner("pong", [message])
```

Notifications declare the RPC methods sent by the server:

```gdscript
extends AlephVault__MMO__Server.ConnectionNotifications

@rpc("authority", "call_remote", "reliable")
func pong(message: String):
	pass
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
	connection.notify_owner("user_sent", [peer_id, "hello"])
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

The chat sample is in `addons/AlephVault.MMO.Samples/samples`.
