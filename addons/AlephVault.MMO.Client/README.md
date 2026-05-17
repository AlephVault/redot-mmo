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

Both peers then address the main node as `/root/MyGame`. User subclasses are
expected, but the matching client/server nodes must keep matching paths.

## Runtime Structure

When a client `Main` enters the tree, it creates:

```text
MyGame
  World
  Protocols
  Connections
    Connection_<peer_id>
      Commands
      Notifications
  MultiplayerSpawner
```

The client only mirrors its own connection node. `Commands` is owned by the
client and is used to call server RPCs. `Notifications` is owned by the server
and receives server RPCs.

## Defining Client Classes

Create a connection subclass and return command and notification nodes:

```gdscript
extends AlephVault__MMO__Client.Connection

const Commands = preload("./my-connection-commands.gd")
const Notifications = preload("./my-connection-notifications.gd")

func _make_commands_node() -> AlephVault__MMO__Client.ConnectionCommands:
	return Commands.new()

func _make_notifications_node() -> AlephVault__MMO__Client.ConnectionNotifications:
	return Notifications.new()
```

Commands declare the RPC methods the client may send:

```gdscript
extends AlephVault__MMO__Client.ConnectionCommands

@rpc("authority", "call_remote", "reliable")
func ping(message: String):
	pass
```

Notifications implement the RPC methods the server may send:

```gdscript
extends AlephVault__MMO__Client.ConnectionNotifications

@rpc("authority", "call_remote", "reliable")
func pong(message: String):
	print("PONG: ", message)
```

Then define a client main subclass:

```gdscript
extends AlephVault__MMO__Client.Main

const Connection = preload("./my-connection.gd")

func connection_class() -> Script:
	return Connection
```

## Connecting

Use the `Main` subclass in the client scene:

```gdscript
var err := my_client.join_server("127.0.0.1", 6777)
var stopped := my_client.leave_server()
```

Useful members:

- `connections: AlephVault__MMO__Client.Connections`
- `world: AlephVault__MMO__Client.World`
- `protocols: AlephVault__MMO__Client.Protocols`
- `spawner: MultiplayerSpawner`
- `address: String`
- `port: int`
- `signal client_started`
- `signal client_stopped`
- `signal client_failed`
- `signal scope_changed(current_scope_id: int, scope_id: int)`

Use `connections.get_connection_node()` to access the current client connection.
