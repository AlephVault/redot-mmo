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

It is better to understand the classes and objects in order. These are the full details for the
involved classes and how to derive them properly.

#### Client-side and server-side command classes

The parent classes are:

- For server: AlephVault__MMO.Server.ConnectionCommands
- For client: AlephVault__MMO.Client.ConnectionCommands

There is no particular members implementation on the client class. There, methods must be annotated
as @rpc (any signature, but "authority" is recommended rather than "any_peer"), and methods should
not have body (since it'll never be invoked).

The server side has more magic here:

1. It must use the same @rpc signature and same name / arguments than what is client-defined.
2. It must implement the body of the method (otherwise the command will be useless).

Also, there are some considerations:

- `_enter_tree()` is implemented. Use `super()` if overriding.
- `connection: AlephVault__MMO.Server.Connection` returns the current server-side connection
  this commands object belongs to.

Following all these guidelines, users can implement any @rpc method they please, always
considering that the authority will be **for the client** in the commands.

#### Client-side and server-side notification classes

The parent classes are:

- For server: AlephVault__MMO.Server.ConnectionNotifications
- For client: AlephVault__MMO.Client.ConnectionNotifications

The server-side has only one authority-related notification:

```
@rpc("authority", "call_remote", "reliable")
func set_scope(id: int):
    pass
```

The client-side implements the body of that command. Its implementation will tell the parent
connection the current scope (which is assigned from the server; see the signals in the next
section for more details).

Following all these guidelines, users can implement any @rpc methods they please, always
considering that the authority will be **for the server** in the notifications.

#### Client-side and server-side connection classes

The connection classes **must be overridden**, or at least _should_. Otherwise, no messages would
be defined through any commands & notifications sub-classes.

Users are free to add **any functionality they want** to the connection (e.g. per-connection logic,
either in the client and/or the server sides). This said, there are some important details to
account for. The connection classses are:

- For server: AlephVault__MMO.Server.Connection
- For client: AlephVault__MMO.Client.Connection

For the server-side class, AlephVault__MMO.Server.Connection, there are some functions to override:

```
func _make_commands_node() -> AlephVault__MMO.Server.ConnectionCommands:
    return YourServerConnectionCommandsClass.new()

func _make_notifications_node() -> AlephVault__MMO.Server.ConnectionNotifications:
    return YourServerConnectionNotificationsClass.new()
```

These methods will be used internally to properly setup everything.

On top of this, this server-side class implements the following features:

- `_enter_tree()` is implemented. Use `super()` if overriding.
- `signal scope_changed(current_scope_id: int, id: int)`: Triggered when the signal is changed for
  this connection. For each connection, the first scope id is -1, when the connection is doing an
  initial setup, even prior to being added to `LIMBO`.
- `id: int`: Returns the Peer ID corresponding to this connection object. This Peer ID is given by
  the underlying Multiplayer API when the connection is established.
- `scope: int`: Returns the current scope of the connection. When not set or invalid, this id is -1
  meaning that there's no scope assigned -not even `LIMBO`- for this connection.
- `commands: AlephVault__MMO.Server.ConnectionCommands`: Returns the commands node, returned by the
  `_make_commands_node` method, when the Connection node is added to the scene.
- `notifications: AlephVault__MMO.Server.ConnectionNotifications`: Returns the notifications node,
  returned by the `_make_notifications_node`, when the Connection node is added to the scene.
- `connections: AlephVault__MMO.Server.Connections`: Returns the parent Connections node. It will
  be explained later.
- `init_authority()`: An internal method. Not intended for end users.
- `notify_owner(method: String, args: Array)`: A convenience method to invoke, from the connection,
  a method in the corresponding notifications node. For example, `notify_owner("foo", [1, 2])`
  can invoke, into the corresponding client, a method like `func foo(a, b)` wrapped as @rpc.

Custom per-game logic can be freely added to this class. Typically, any required instance member is
OK and, instead of standard static members, static per-`connections` functions, so instances can
launch them by also considering the current `connections` parent.

For the client class, the implementation is similar:

```
func _make_commands_node() -> AlephVault__MMO.Client.ConnectionCommands:
    return YourClientConnectionCommandsClass.new()

func _make_notifications_node() -> AlephVault__MMO.Client.ConnectionNotifications:
    return YourClientConnectionNotificationsClass.new()
```

These methods will be used internally to properly setup everything.

On top of this, this client-side class implements the following features:

- `_enter_tree()` is implemented. Use `super()` if overriding.
- `signal scope_changed(current_scope_id: int, id: int)`: Triggered when the signal is changed for
  this connection. For each connection, the first scope id is -1, when the connection is doing an
  initial setup, even prior to being added to `LIMBO`.
- `id: int`: Returns the Peer ID corresponding to this connection object. This Peer ID is given by
  the underlying Multiplayer API when the connection is established.
- `scope: int`: Returns the current scope of the connection. When not set or invalid, this id is -1
  meaning that there's no scope assigned -not even `LIMBO`- for this connection.
- `commands: AlephVault__MMO.Client.ConnectionCommands`: Returns the commands node, returned by the
  `_make_commands_node` method, when the Connection node is added to the scene.
- `notifications: AlephVault__MMO.Client.ConnectionNotifications`: Returns the notifications node,
  returned by the `_make_notifications_node`, when the Connection node is added to the scene.
- `connections: AlephVault__MMO.Client.Connections`: Returns the parent Connections node. It will
  be explained later.
- `init_authority()`: An internal method. Not intended for end users.

They typically mirror what was explained in the server-side, completely. However, the logic that a
user should add here is only UX-related, not "source-truth" logic in any way.

There's also an important thing to remark here: In the client-side, only the object that
corresponds to the established connection is mirrored, and not _all_ the connection objects. It
would also not make sense to do so, since no properties are mirrored in that case and typically
all the methods will be either client-to-server or server-to-client, and never peer-to-peer.

#### Client-side and server-side main object classes

Once having the client-side and server-side components properly defined, it's time to create the
client and server sub-classes themselves. The idea is always to override the parent Main classes:

- For server: AlephVault__MMO.Server.Main
- For client: AlephVault__MMO.Client.Main

Overriding them involves defining the proper client-side and server-side Connection classes and
then referencing them in the client-side and server-side Main objects respectively.

When deriving the server-side Main component, override this method like this:

```
func connection_class() -> Script:
    return MyServerConnection
```

Users can add any custom logic needed in the server side, if they want.

When deriving the client-side Main component, override this method like this:

```
func connection_class() -> Script:
    return MyClientConnection
```

Users can add any custom logic needed in the client side, if they want.

Still, however, there are features that must be known in server-side and client-side.

In server-side Main component:

- `launch(port: int, max_clients: int = 4095, max_channels: int = 0, in_bandwidth: int = 0, out_bandwidth: int = 0) -> Error`: Start the server.
- `stop() -> bool`: Stops a launched server.
- `port: int`: For a launched server, the port it's listening on.
- `address: String`: For a launched server, the address it's listening on.
- `connections: AlephVault__MMO.Server.Connections`: The Connections node.
  This one will be explained later.
- `spawner: MultiplayerSpawner`: The spawner node. It's used in a standard way. Its node path is
  set to the `world` of this server.
- `world: AlephVault__MMO.Server.World`: Stands for the root node of replicable / spawnable
  objects, following the standard `MultiplayerSpawner` features.
- `signal scope_changed(connection_id: int, current_scope_id: int, scope_id: int)`: Triggered when
  a connection has its scope changed.
- `signal server_started` and `signal server_stopped`: Triggered when the server starts and stops,
  respectively. Everything ought to be considered _relevant_ occurs in-between.
- `signal client_entered(id: int)` and `signal client_left(id: int)`: Triggered when a connection
  is established and terminated, respectively. Everything ought to be considered _relevant_ for
  that connection will occur in-between.
- `_ready()` is implemented. Use `super()` if overriding.
- `_exit_tree()` is implemented. Use `super()` if overriding.

**NOTES**: The `connections`, `spawner` and `world` nodes are added when this Main node is properly
added to the scene tree, and removed when it's removed from the scene tree. They will not exist in
other moments.

For the client Main component, many of these features work similarly or mirrored:

- `join_server(address: String, port: int, channel_count: int = 0, in_bandwidth: int = 0, out_bandwidth: int = 0, local_port: int = 0) -> Error`: Attempts to join a server.
- `leave_server() -> bool`: Leaves a server, if one is joined.
- `port: int`: When joined to a server, the server's port.
- `address: String`: When joined to a server, the server's address.
- `connections: AlephVault__MMO.Client.Connections`: The Connections node.
  Mirrored from the server side, but will only contain a node for the _current_ connection.
- `spawner: MultiplayerSpawner`: The spawner node. It's used in a standard way. Its node path is
  set to the `world` of the server, and mirrored in the same path for the client.
- `world: AlephVault__MMO.Client.World`: Stands for the root node of replicable / spawnable
  objects, following the standard `MultiplayerSpawner` features. Mirrores from the server.
- `signal scope_changed(current_scope_id: int, scope_id: int)`: Triggered when this connection has
  its scope changed from the server side. This signal is bubbled from the only connection node that
  exists in this client hierarchy.
- `signal client_started` and `signal client_stopped`: Triggered when the client joined a server
  and when the client terminated that connection, respectivaly. Everything ought to be considered
  relevant occurs in-between.
- `signal client_failed`: Triggered when a client fails to connect to a server.
- `_ready()` is implemented. Use `super()` if overriding.
- `_exit_tree()` is implemented. Use `super()` if overriding.

**NOTES** just like in the server side, the `connections`, `spawner` and `world` nodes are managed
in the same way and for analogous reasons.

#### Client-side and server-side connections object

The Connections object is a very special object due to the internal features and how they
interact with the connection nodes and the scopes they belong do.

Just to start, there are some concepts to clarify:

1. There are many potential scopes that can be defined. Some of them are deemed _special_, while
   others are deemed _default_ or _dynamic_, having few differences other than their life-cycle.
2. At least one special scope named `LIMBO` exists, and newly created connections (when a client
   successfully joins the server) with immediately move to that scope.
3. Users can define new default, dynamic or even special scopes. Typically, special scopes are not
   meant to allow users to interact but represent certain states in the game where the connection
   needs further setup prior to interacting with anyone (e.g. login, create account, select a
   character, ...).

So, in the server side, the Connections node keeps the different connections that exist in a given
moment while, in the client side, only one corresponding connection is mirrored. Also, the server
side decides (via custom user logic) which scopes the connections will go to, while the client side
just reflects whatever scope is updated from the server (in both sides a `scope_changed` signal
exists to keep track, in a node, of the scope for a connection).

The life-cycle goes like this:

1. When a client successfully joins a server, the server instantiates a connection node (of the
   appropriate class from the `connection_class()` method), asigning the just-fetched connection id
   from it, adding the node under the `Connections` node (with a unique name involving also the id)
   and finally initializing its authority.
2. The authority initialization of a node involves creating its `Commands` and `Notification` nodes
   directly under the connection node itself. Those nodes are granted authorities: the first goes
   for the client connection, while the second goes for the server (since it's up to the client to
   send the commands, and up to the server to send the notifications).
3. In the meantime, the client does the exact same/analogous process (also ensuring the same name
   is given to the nodes) and assigning the same authorities to the same objects in their side.
4. The client sends commands to the server, directly invoking `.rpc()` on the properly defined and
   annotated methods. Commands will have the "authority" modifier in the `@rpc` decorator.
5. The server sends notifications to the client, directly invoking `.rpc_id()` on the properly
   defined and annotated methods, or perhaps using `notify_owner` for the same purpose.
6. The server can also set the scope for a connection. At init time, the scope is not set (it will
   be -1) and, as immediate as possible, the connection will be moved to `LIMBO` when added to the
   Connections object. `scope_changed` is a signal triggered in both client and server side of a
   Connection node when this happens.
7. The server can also iterate over the objects of a given scope. This can be done for any reason,
   but typically intended to send a notification to many clients in the same loop.
8. The server can know the scope of a given connection.
9. When the client connection is terminated, the client destroys the connection node and children,
   while the server destroys in particular also that corresponding node and children.

Is is always worth clarifying: All the in-hierarchy names match between nodes, thus keeping the
proper RPC synchronization mechanism working.

Both the server-side and the client-side Main components have a `connections` property to get the
Connections object. The full features in the Connection supporting the described life-cycle in the
points 6, 7 and 8 come as follows:
    
In the server side:

- `get_connections_in_scope(scope_id: int) -> Array[int]`: Given a scope_id, retrieves all the ids
  of the connections added to that scope.
- `get_connection_scope(connection_id: int) -> int`: Given the id of a connection, returns which
  scope is it added to. It returns -1 if the connection is not valid or not set up by that point.
- `set_connection_scope(connection_id: int, scope_id: int)`: Sets the scope_id for a connection.
  The scope must be a valid assembled id (see in the explanation about assembling one), but it is
  not required for the ID to exist or be validated in any way.
- `has_connection(connection_id: int) -> bool`: Tells whether the connection exists as a node or
  not (this validates the connection in the life-cycle). If this method returns false, it also
  means that the connection_id is not a valid MultiplayerAPI peer id, or ceased to be valid.
- `get_connections() -> Array[int]`: Gets all the connection ids. This array may be big (e.g. up
  to 4095 elements or whatever maximum is configured). All the ids will be valid peer ids by that
  point.
- `get_connection_node(id: int) -> AlephVault__MMO.Server.Connection`: Given a peer id, returns
  the corresponding connection node for it. This means: given a peer id, returns the connection
  object for that peer. This one will be highly used to interact with most of the relevant logic,
  save for scope-iterating (described next).
- `scope_iterate(scope_id: int, method: Callable)`: Iterates a scope. This means: iterates over
  the connections inside that scope and executes a particular method for that node. The passed
  method (second argument) receives the corresponding server-side Connection object for the peer
  id being iterated. It is intended for scope-wide actions rather then user-wide actions as in the
  `get_connection_node` method. Anything can be used as logic in the `method`. However, if the idea
  is to notify something, the method's code block can be a one-liner like
  `node.notify_owner("foo", [1, 2])` or any notification as described in the `notify_owner` in the
  server-side Connection object.
- `has_scope(scope_id: int) -> bool`: Tells whether the scope is in use or not.

In the client side:

- `get_connection_node() -> AlephVault__MMO.Client.Connection`: Gets the only available connection
  node in the Connections (it will correspond to the current connection).

The involved `scope_id` is a number that can be assembled and disassembled with the features of
the AlephVault__MMO.Common.Scopes class:
    
- `SCOPE_LIMBO: int = 0`: A constant for the LIMBO special scope.
- `SCOPE_ACCOUNT_DASHBOARD: int = 1`: A constant for the ACCOUNT DASHBOARD special scope.
- `ScopeType.DEFAULT = 0`: The type for "default" (always loaded) scopes.
- `ScopeType.DYNAMIC = 1`: The type for "dynamic" (on-demand loaded) scopes.
- `ScopeType.SPECIAL = 2`: The type for "special" scopes (not intended for user interaction).
- `static make_fq_scope_id(id: int, scope_type: ScopeType) -> int`: Assembles a scope_id from the
  chosen type id and the (relative) id.
- `static unpack_scope_id(id: int) -> Dictionary`: Disassembles a scope_id into the values that
  made them. The result is a dictionary whose keys are: "id" -> The relative id, "type": one of the
  three types (0/DEFAULT, 1/DYNAMIC, 2/SPECIAL).
- `static make_fq_default_scope_id(id: int) -> int`: Invokes `make_fq_scope_id` specifying the
  ScopeType.DEFAULT type.
- `static make_fq_dynamic_scope_id(id: int) -> int`: Invokes `make_fq_scope_id` specifying the
  ScopeType.DYNAMIC type.
- `static make_fq_special_scope_id(id: int) -> int`: Invokes `make_fq_scope_id` specifying the
  ScopeType.SPECIAL type.
