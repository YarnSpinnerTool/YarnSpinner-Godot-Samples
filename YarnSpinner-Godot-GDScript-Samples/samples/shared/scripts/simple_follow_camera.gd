class_name SimpleFollowCamera
extends Node3D


@export var target: Node3D
@export var camera: Camera3D
@export var follow_offset := Vector3(0.0, 1.76, 1.78)
@export var look_at_offset := Vector3(0.0, 0.91, 0.0)


func _process(_delta: float) -> void:
	if target == null:
		return

	global_position = target.global_position + follow_offset

	if camera != null:
		camera.look_at(target.global_position + look_at_offset, Vector3.UP)
