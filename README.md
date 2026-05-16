# redot-mmo

A Redot/Godot add-on collection for MMO-style games.

This repository currently contains:

- `AlephVault.MMO.Common`: shared MMO helpers such as scope ids.
- `AlephVault.MMO.Client`: client-side multiplayer node structure,
  connection helpers, commands, and notifications. Depends on the
  `AlephVault.MMO.Common` package.
- `AlephVault.MMO.Server`: server-side multiplayer node structure,
  connection helpers, commands, notifications, and scope management.
  Depends on the `AlephVault.MMO.Common` package.
- `AlephVault.MMO.Samples`: sample scenes and scripts using the client
  and server packages. Depends on both `AlephVault.MMO.Client` and the
  `AlephVault.MMO.Server` packages.
- `AlephVault.MMO.Storage`: a standard HTTP remote-storage client for account,
  profile, inventory, character, or game-state data.

## Installation

This package might be available in the Redot/Godot Asset Library. However, it can also be installed
right from this repository, provided the contents of the `addons/` directory are added into the
project's `addons/` directory.

## Documentation

- [AlephVault.MMO.Common](addons/AlephVault.MMO.Common/README.md)
- [AlephVault.MMO.Client](addons/AlephVault.MMO.Client/README.md)
- [AlephVault.MMO.Server](addons/AlephVault.MMO.Server/README.md)
- [AlephVault.MMO.Storage](addons/AlephVault.MMO.Storage/README.md)
