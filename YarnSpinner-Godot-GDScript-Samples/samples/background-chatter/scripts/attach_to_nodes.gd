# This Source Code Form is subject to the terms of the LICENSE.md file
# located in the root of this project.

@tool
class_name AttachToNodes
extends Node3D
## keeps this node positioned at the average of the target nodes'
## positions, every frame, in the editor and at runtime.

## the nodes to average
@export var targets: Array[Node3D] = []


func _process(_delta: float) -> void:
	if targets.is_empty():
		return

	var position_sum := Vector3.ZERO
	var count := 0
	for target in targets:
		if target != null and is_instance_valid(target):
			position_sum += target.global_position
			count += 1

	if count > 0:
		global_position = position_sum / count
