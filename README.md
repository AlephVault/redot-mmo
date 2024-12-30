# redot-mmo
A Redot/Godot add-on to make multiplayer massive online games

## Installation

This package might be available in the Redot/Godot Asset Library. However, it can also be installed
right from this repository, provided the contents of the `addons/` directory are added into the
project's `addons/` directory.

## Usage

This is mainly based on the [Multiplayer API](https://docs.godotengine.org/en/stable/classes/class_multiplayerapi.html),
so a deep understanding of the Multiplayer API is needed first (if you don't
know, take a look).

### MultiplayerAPI Requirement: Mirrored structure

As an example, consider that **it is required that the client and the server are located in the
same path** in their respective scenes, which is a requirement in the Multiplalyer API itself.

For example, let's say you have a project, with two scenes files:

  1. `res://client/scenes/main-scene.tscn` - Intended for the client program.
  2. `res://server/scenes/main-scene.tscn` - Intended for the server program.

Just as a reminder, the path of the scene files doesn't matter. You can use any resource path to
store your scenes.

However, inside each involved scene (two, in this case) the object hierarchies must be the same for
the messages to be passed each time.

#### Example 1:

Server's main-scene.tscn:

```
◯ MyGame (Node of type AlephVault_MMO.Server.Main, or a sub-type)
```

Client's main-scene.tscn:

```
◯ MyGame (Node of type AVAlephVault_MMO.Client.Main, or a sub-type)
```

Notice how the classes are different: The client will use `AVAlephVault_MMO.Client.Main` while the
server will use `AlephVault_MMO.Server.Main`. This will be explained later, but typically only
matching client/server (sub-)classes will be used, and it is not just acceptable but *expected*
that users create their own sub-classes for each case.

Still, both paths will be `/root/MyGame`. It's important that the paths match.

#### Example 2:

Server's main-scene.tscn:

```
◯ Foo (Whatever)
	◯ Bar (Whatever)
		◯ MyAwesomeGame (Node of type AlephVault_MMO.Server.Main, or a sub-type)
```

Client's main-scene.tscn:

```
◯ Foo (Whatever)
	◯ Bar (Whatever)
		◯ MyAwesomeGame (Node of type AVAlephVault_MMO.Client.Main, or a sub-type)
```

In this case, the structure is arbitrary. Still, **both the client and the server** will live under
the same **path**. It doesn't matter whether the classes for the Foo and Bar nodes are the same or
different, but the **names** must match.

In this case, `/root/Foo/Bar/MyAwesomeGame` both in client and server,
regardless the classes.

And, still, the classes must also be client/server matching (sub-)classes applying the same
principles in the previous example (where users develop their own subclasses).

### Understanding the full run-time client and server architecture

When the server is running (and this applies respectively to the client as well), new nodes are
spawned under the `Main` component. The full structure ends looking like this:

Notes: This applies to the Example 1.

```
◯ MyGame (Node of type AlephVault_MMO.Server.Main, or a sub-type)
    ◯ World (Node of type AlephVault_MMO.Server.World, named "World")
    ◯ Connections (Node of type AlephVault_MMO.Server.Connections, named "Connections")
    ◯ MultiplayerSpawner (Node of type MultiplayerSpawner, named "MultiplayerSpawner")
```

For the client, a `World`, a `Connections` and a `MultiplayerSpawner` will also exist, but they
will be of client-side classes (similarly named).

The `MultiplayerSpawner` object has its own documentation and will be directly used by the
developer. Check it [here](https://docs.godotengine.org/en/stable/classes/class_multiplayerspawner.html).
It's configured to use the `World` as root for objects replication.

The `World` will be explained later, since it has its own subtle details.

The `Connections` is a container of objects which represent an individual client connection each.
For example let's say that, at a given moment, three connections are established with the ids: 37,
224 and 1000. The server will look like this:

```
◯ MyGame (Node of type AlephVault_MMO.Server.Main, or a sub-type)
    ◯ World (Node of type AlephVault_MMO.Server.World, named "World")
    ◯ Connections (Node of type AlephVault_MMO.Server.Connections, named "Connections")
        ◯ Connection_37 (Node of type AlephVault_MMO.Server.Connection, or a sub-type).
            ◯ Commands (This will be explained later)
            ◯ Notifications (This will be explained later)        
        ◯ Connection_224 (Node of type AlephVault_MMO.Server.Connection, or a sub-type).
            ◯ Commands (This will be explained later)
            ◯ Notifications (This will be explained later)        
        ◯ Connection_1000 (Node of type AlephVault_MMO.Server.Connection, or a sub-type).
            ◯ Commands (This will be explained later)
            ◯ Notifications (This will be explained later)        
	◯ MultiplayerSpawner (Node of type MultiplayerSpawner, named "MultiplayerSpawner")
```

Where the names of the Connection nodes are exactly of that pattern.

Now, for each client (e.g. 37), the structure will look like this:

```
◯ MyGame (Node of type AlephVault_MMO.Client.Main, or a sub-type)
    ◯ World (Node of type AlephVault_MMO.Client.World, named "World")
    ◯ Connections (Node of type AlephVault_MMO.Client.Connections, named "Connections")
        ◯ Connection_37 (Node of type AlephVault_MMO.Client.Connection, or a sub-type).
            ◯ Commands (This will be explained later)
            ◯ Notifications (This will be explained later)        
    ◯ MultiplayerSpawner (Node of type MultiplayerSpawner, named "MultiplayerSpawner")
```

This means: each client will only have a mirror node _for its own connection_.

Connections are automatically created and removed when the underlying MultiplayerAPI connection is
started or terminated, respectivaly, and this happens both in the client-side and the server-side.

Pretty much like choosing a client/server Main class pair, a proper client/server Connection class
pair will be chosen. This will be explained in the next section.

### Creating your own server and client classes

The first thing to do when interacting with this package is to actually create:

  1. A subclass of `AlephVault_MMO.Client.Connection`.
     1. Proper Commands and Notifications sub-classes.
  2. A subclass of `AlephVault_MMO.Client.Main`, specifying the new subclass for connections.
  3. A subclass of `AlephVault_MMO.Server.Connection`.
     1. Proper Commands and Notifications sub-classes.
  4. A subclass of `AlephVault_MMO.Server.Main`, specifying the new subclass for connections.

#### Defining the Client Connection sub-class

A connection is an object that will have three types of features:

  1. A server-authority "Notifications" sub-node object.
  2. A client-authority "Commands" sub-node object.
  3. Optionally, per-game data (in fact, there _is_ some default general data in the base
     connection).

When setting a connection up, the connection will internally create the two sub-nodes: one so that
the client sends RPC calls to the server, and one so that the server sends RPC calls to that client
(and only THAT client). RPC calls are fully described in the Multiplayer API documentation and the
concept and all its variations will fully apply here.

So let's consider a simple Connection example consisting of PING / PONG messages:

File: `client/my-connection.gd`
```
extends AlephVault__MMO.Client.Connection

const _commands_class = preload("./my-connection-commands.gd")
const _notifications_class = preload("./my-connection-notifications.gd")

func _make_commands_node() -> AlephVault__MMO.Client.ConnectionCommands:
	return _commands_class.new()

func _make_notifications_node() -> AlephVault__MMO.Client.ConnectionNotifications:
	return _notifications_class.new()
```

File: `client/my-connection-commands.gd`
```
extends AlephVault__MMO.Client.ConnectionCommands

@rpc("authority", "call_remote", "reliable")
func ping(message: String):
	# No implementation here.
	pass
```

File: `client/my-connection-notifications.gd`
```
extends AlephVault__MMO.Client.ConnectionNotifications

@rpc("authority", "call_remote", "reliable")
func pong(message: String):
	print("PONG: ", message)
```

Notice how the client will not implement the body of `ping`, since it's a command that the server
must implement. Instead, it will implement the body of `pong`, since it's the client the one who
implements behaviour to whatever the server sends as notification.

#### Defining the Client Main sub-class

The only thing the client needs to do a priori is to set the connection class. An example:

File: `client/main.gd`
```
extends AlephVault__MMO.Client.Main

const _connection_class = preload("./my-connection.gd")

func connection_class() -> Script:
	return _connection_class
```

This is the extremely basic needed contents for a client setup (more details will be given later).

#### Defining the Server Connection sub-class

The server specification is analogous to the client, but with inverted responsibilities. Notice
how, however, the signatures for the RPC methods will be the same, but the responsibility for
implementing them will be swapped. Let's follow the same example:

File: `server/my-connection.gd`
```
extends AlephVault__MMO.Server.Connection

const _commands_class = preload("./my-connection-commands.gd")
const _notifications_class = preload("./my-connection-notifications.gd")

func _make_commands_node() -> AlephVault__MMO.Server.ConnectionCommands:
	return _commands_class.new()

func _make_notifications_node() -> AlephVault__MMO.Server.ConnectionNotifications:
	return _notifications_class.new()
```

File: `server/my-connection-commands.gd`
```
extends AlephVault__MMO.Client.ConnectionCommands

@rpc("authority", "call_remote", "reliable")
func ping(message: String):
	connection.notify_owner("pong", [message])
```

File: `server/my-connection-notifications.gd`
```
extends AlephVault__MMO.Client.ConnectionNotifications

@rpc("authority", "call_remote", "reliable")
func pong(message: String):
	# No implementation here.
	pass
```

In this case, the only implementation for the `ping` command is to answer with a `pong` command,
passing as an array the needed arguments for that command (in this case: the same single message
value sent by the user).

#### Defining the Server Main sub-class

Analogous to the client, the server sub-class will be like this:

File: `server/main.gd`
```
extends AlephVault__MMO.Server.Main

const _connection_class = preload("./my-connection.gd")

func connection_class() -> Script:
	return _connection_class
```

### Launching your newly created client and server

Ideally, the new respective `Main` sub-classes will have their own `class_name`. It's time to
use them in your scenes.

Create the two relevant scenes and ensure the same top hierarchy is present in both scenes.

Then, create the respective _main_ nodes under that hierarchy, each of the proper class that
is needed (the server subclass in the server scene, and the client subclass in the client one)
and also having the _same_ name each time.

Then, provided proper access to those nodes is attempted, choose a port of your preference
(e.g. 6776) and launch / stop a server doing this:

```
# Launch it with:
Error r = my_server.launch(6776)

# Stop it with:
bool stopped = my_server.stop()
```

While the server is running, try making clients connect to it:

```
# Join a server with:
Error r = my_client.join_server("127.0.0.1", 6776)

# Leave a server with:
bool stopped = my_client.leave_server()
```

### Understanding scopes

Scopes represent a way of grouping connections. Think of it as maps or rooms where other players
are interacting: Depending on which room a player is in, they will be able to interact with players
in that room and NOT players in another rooms (save for features like private messages, if that is
ever implemented).

Just like public chat systems like IRC define channels, and MMORPGs define maps, scopes abstract
those concepts. Here, scopes are categorized in three groups:

  1. "Special" scopes are scopes that serve particular purposes, usually different to allowing
	 contexts for users to communicate / interact through. Two of them are provided by default but
	 new ones can be configured per-game. The default ones are "limbo" (which is used by default
	 as a "currently, no scope" concept) and "account dashboard", intended for users creating games
	 where an account can have more than one profile and there's a moment where the users must pick
	 one of those profiles in the account before actually playing.
  2. "Default" scopes are intended for levels and channels that will always exist (e.g. static maps
	 in a game). Users can interact here.
  3. "Dynamic" scopes are intended for levels and channels that will exist on demand (e.g. dynamic
	 chat rooms) and can be freed also on demand. Users can interact here.

When a connection is just established, it starts in the "LIMBO" special scope and must be moved, by
purely server-side logic, to any other scope.

#### Scope IDs

The first thing to do is to get a scope id to move connections to.
Special scope IDs are made like this:

```
# Special scopes
const LIMBO = AlephVault__MMO.Common.Scopes.make_fq_special_scope_id(AlephVault__MMO.Common.Scopes.SCOPE_LIMBO)
const ACCOUNT_DASHBOARD = AlephVault__MMO.Common.Scopes.make_fq_special_scope_id(AlephVault__MMO.Common.Scopes.SCOPE_ACCOUNT_DASHBOARD)
const ANOTHER_SCOPE = AlephVault__MMO.Common.Scopes.make_fq_special_scope_id(FOO)
```

The argument for the `make_fq_special_scope_id` is a regular `int` value.
For the default and dynamic scopes, the idea is similar:

```
# Default scope 1
const some_default_scope = AlephVault__MMO.Common.Scopes.make_fq_default_scope_id(1)

# Dynamic scope 1
const some_dynamic_scope = AlephVault__MMO.Common.Scopes.make_fq_dynamic_scope_id(1)

# The end values for both scopes will be DIFFERENT.
```

#### Managing connection in a scope by its id

In server-side, given by the MultiplayerAPI's id of each connection, they can be
put into, and taken from, specific scopes (being them special, default or
dynamic). To achieve that, some sample code is:

```
var some_main: AlephVault__MMO.Server.Main = ...whatever...
var connections: AlephVault__MMO.Server.Connections = some_main.connections

# Move a connection from a current scope, if any, to one of our scopes.
# In this case, our dynamic scope.
connections.set_connection_scope(some_connection, some_dynamic_scope)

# Tell the current scope of a connection.
var scope_id: int = connections.get_connection_scope(some_connection)
assert(scope_id == somy_dynamic_scope, "The scopes will match")

# Get all the connections in the same scope.
var all_connections: Array[int] = connections.get_connections_in_scope(scope_id)

# Do something for each node in a connection. While a for loop over
# the all_connections array is practically the same, this method avoids
# creating that intermediate array in first place.
var some_function: Callable = func(connection: AlephVault__MMO.Server.Connection):
	# do_something_with connection
connections.scope_iterate(scope_id, some_function)
```

### Managing scopes and connections: Full API reference

`TODO`
