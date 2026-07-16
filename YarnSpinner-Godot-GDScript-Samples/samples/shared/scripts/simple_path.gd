class_name SimplePath
extends Node3D

## A looping waypoint path for a [SimpleCharacter] to roam along: an ordered
## list of points, each with an optional pause the character waits out before
## moving to the next.
##
## Each child [Marker3D] is a waypoint, used in tree order. Give a marker a float
## metadata entry named "delay" (seconds) to make the character pause there.

const _DELAY_META := &"delay"


## Number of waypoints on the path.
func count() -> int:
	return _waypoints().size()


## World position of waypoint [param index].
func world_position(index: int) -> Vector3:
	var points := _waypoints()
	if index < 0 or index >= points.size():
		return global_position
	return points[index].global_position


## Seconds to wait once waypoint [param index] is reached (0 if none set).
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
