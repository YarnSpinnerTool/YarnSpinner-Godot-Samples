class_name RoomLayout
extends Resource

## Where the two characters stand for one room, and the environment that is
## built around them. The level god loads the layout matching the currently
## selected room and applies it when a scenario starts.

## Where the primary character stands. Leave unset to leave them where they are.
@export var primary: CharacterSpawn
## Where the secondary character stands. Leave unset to leave them where they are.
@export var secondary: CharacterSpawn
## The room built around the characters for this layout.
@export var environment_scene: PackedScene
