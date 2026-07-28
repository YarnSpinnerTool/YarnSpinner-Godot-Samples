class_name CharacterSpawn
extends Resource

## A place for a character to stand, used by [RoomLayout].

@export var position: Vector3
## Facing, as a rotation about the Y axis in degrees.
@export_range(-180.0, 180.0, 0.001, "or_greater", "or_less") var rotation_degrees: float


## The direction this spawn faces, for [method SimpleCharacter.set_look_direction].
## The pill characters' art faces +Z, so that is the spawn's forward too.
func look_direction() -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(rotation_degrees)) * Vector3.BACK
