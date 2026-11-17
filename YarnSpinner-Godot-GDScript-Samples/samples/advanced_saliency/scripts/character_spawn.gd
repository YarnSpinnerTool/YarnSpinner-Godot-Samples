class_name CharacterSpawn
extends Resource


@export var position: Vector3
@export_range(-180.0, 180.0, 0.001, "or_greater", "or_less") var rotation_degrees: float


func look_direction() -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(rotation_degrees)) * Vector3.BACK
