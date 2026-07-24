class_name DebugFollowMouse
extends Node
## the character to drive; found by name if left unset
@export var character: SimpleCharacter
@export var character_name := "Capsley"
@export var toggle_key: Key = KEY_F10
## how far the mouse point must move before the walk is retargeted
@export var retarget_distance := 0.25

var _enabled := false
var _last_target := Vector3.INF
var _saved_mode := SimpleCharacter.Mode.PLAYER_CONTROLLED
var _saved_look: Node3D


func _ready() -> void:
	if character == null:
		var root := get_tree().current_scene if get_tree().current_scene != null else owner
		if root != null:
			character = root.find_child(character_name, true, false) as SimpleCharacter


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == toggle_key:
		_set_enabled(not _enabled)
		get_viewport().set_input_as_handled()


func _set_enabled(on: bool) -> void:
	_enabled = on
	if character == null:
		return
	if on:
		_saved_mode = character.mode
		_saved_look = character.look_target
		print("DebugFollowMouse: ON (%s follows the mouse; %s to stop)" % [character.name, OS.get_keycode_string(toggle_key)])
	else:
		character._move_id += 1  # abandon any walk in flight
		character.current_speed_factor = 0.0
		character.mode = _saved_mode
		character.look_target = _saved_look
		_last_target = Vector3.INF
		print("DebugFollowMouse: OFF")


func _process(_delta: float) -> void:
	if not _enabled or character == null or not character.is_inside_tree():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	# intersect the ray with the character's ground plane
	var plane := Plane(Vector3.UP, character.global_position.y)
	var hit: Variant = plane.intersects_ray(origin, direction)
	if hit == null:
		return
	var point: Vector3 = hit
	if point.distance_to(character.global_position) < 0.2:
		return
	if _last_target != Vector3.INF and point.distance_to(_last_target) < retarget_distance:
		return
	_last_target = point
	character.move_to(point)
