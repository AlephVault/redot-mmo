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

Just as a reminder, the path of the scene files doesn't matter. You can use any resource path to store your scenes.

However, inside each involved scene (two, in this case) the object hierarchies must be the same for the messages to be passed each time.

#### Example 1:

Server's main-scene.tscn:

```
◯ MyGame         (Node of type AlephVault_MMO.Server.Main, or a sub-type)
```

Client's main-scene.tscn:

```
◯ MyGame         (Node of type AVAlephVault_MMO.Client.Main, or a sub-type)
```

Notice how the classes are different: The client will use `AVAlephVault_MMO.Client.Main` while the
server will use `AlephVault_MMO.Server.Main`. This will be explained later, but typically only
matching client/server (sub-)classes will be used, and it is not just acceptable but *expected*
that users create their own sub-classes for each case.

Still, both paths will be `/root/MyGame`. It's important that the paths match.

#### Example 2:

Server's main-scene.tscn:

```
◯ Foo         (Whatever)
	◯ Bar         (Whatever)
		◯ MyAwesomeGame         (Node of type AlephVault_MMO.Server.Main, or a sub-type)
```

Client's main-scene.tscn:

```
◯ Foo         (Whatever)
	◯ Bar         (Whatever)
		◯ MyAwesomeGame         (Node of type AVAlephVault_MMO.Client.Main, or a sub-type)
```

In this case, the structure is arbitrary. Still, **both the client and the server** will live under the same **path**.
It doesn't matter whether the classes for the Foo and Bar nodes are the same or different, but the **names** must match.

In this case, `/root/Foo/Bar/MyAwesomeGame` both in client and server, regardless the classes.

And, still, the classes must also be client/server matching (sub-)classes applying the same principles in the previous
example (where users develop their own subclasses).

### Understanding the full run-time client and server architecture

### Creating your own server and client classes

The next thing to do is to create the client and server classes, as well as everything related: the
connections, the commands, and the notifications. However, prior to start creating them, let's take
a look to the related concepts.

#### Per-client connections mirroring

Still applying the mirroring of the whole structure for the RPC calls to work (again: this one is a
requirement from the Multiplayer API itself, and not from this package), connections are organized
in a particular way in the server.