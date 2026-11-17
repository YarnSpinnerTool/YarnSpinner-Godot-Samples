class_name SimplePath
extends Node3D


const _DELAY_META := &"delay"


func count() -> int:
	return _waypoints().size()


func world_position(index: int) -> Vector3:
	var points := _waypoints()
	if index < 0 or index >= points.size():
		return global_position
	return points[index].global_position


func delay(index: int) -> float:
	var points := _waypoints()
	if index < 0 or index >= points.size():
		return 0.0
	return float(points[index].get_meta(_DELAY_META, 0.0))


func _waypoints() -> Array[Marker3D]:
	var result: Array[Marker3D] = []
	for child in get_children():
		if child is Marker3D:
			result.append(child as Marker3D)
	return result
