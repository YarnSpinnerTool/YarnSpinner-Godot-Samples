class_name SimpleFollowCamera
extends Node3D

## A camera rig that follows a target at a fixed offset and looks at it.
## Each frame the rig sits at target + follow_offset, and the child camera
## looks at target + look_at_offset.

@export var target: Node3D
@export var camera: Camera3D
## The rig sits 1.78 units behind the target on +Z.
@export var follow_offset := Vector3(0.0, 1.76, 1.78)
@export var look_at_offset := Vector3(0.0, 0.91, 0.0)


func _process(_delta: float) -> void:
	if target == null:
		return

	global_position = target.global_position + follow_offset

	if camera != null:
		camera.look_at(target.global_position + look_at_offset, Vector3.UP)
