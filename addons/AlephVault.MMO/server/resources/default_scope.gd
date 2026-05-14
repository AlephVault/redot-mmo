extends Resource
## This is a default scope setup for an arbitrary
## game layout (it can be a 2D or 3D game, or just
## pure-UI game). The most important concept here
## is the related scene, but there's also a notion
## of additional data that can be used when setting
## this scope up: the custom data (for 2D games, it
## might include the start position, while for 3D
## games it might include the start position as a
## 3D vector).

## This is the scene. It must not be null (otherwise
## the resource will be ignored).
@export var scene: PackedScene;

## An extra function to return extra setup data. By
## default it returns null.
func setup():
	return null
