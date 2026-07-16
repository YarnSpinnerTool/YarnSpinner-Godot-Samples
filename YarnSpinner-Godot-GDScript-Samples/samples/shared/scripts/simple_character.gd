class_name SimpleCharacter
extends CharacterBody3D

## A small walk-around character controller shared by the 3D samples.
##
## Player-controlled movement with smoothed acceleration and turn-to-face, plus
## externally-driven movement ([method move_to]) and a look target so NPCs can
## turn to face whoever they're talking to. The walk/idle animation blend is
## driven from the current speed.

enum Mode {
	PLAYER_CONTROLLED,      ## reads input each frame
	EXTERNALLY_CONTROLLED,  ## driven by move_to / commands
	PATH_FOLLOWING,         ## roams a looping waypoint path
	INTERACT,               ## paused while interacting
}

@export var is_player_controlled := false

@export_group("Movement")
@export var speed := 3.0
## degrees per second the character turns to face its target direction
@export var turn_speed := 500.0
@export var gravity := 10.0
## Stationary characters that stand on a prop (e.g. the town crier on his box)
## keep their authored height instead of falling to the ground.
@export var apply_gravity := true
## smoothing time (seconds) when speeding up / slowing down
@export var acceleration := 0.2
@export var deceleration := 0.1
## the player is warped back to the last solid ground if it falls below this
@export var out_of_bounds_y := -5.0

@export_group("Path")
## A [SimplePath] of waypoint markers to roam along. When set (and not
## player-controlled), the character starts on the path and loops it.
@export var follow_path: SimplePath
## How close the character must get to a waypoint to count as having reached it.
@export var path_destination_tolerance := 0.1

@export_group("Interaction")
## player only: how close an interactable must be to be selectable
@export var interaction_radius := 1.0
## offset from the character's origin used as the interaction sample point
@export var interaction_offset := Vector3(0, 0, 0.3)

@export_group("Animation")
@export var animation_tree: AnimationTree
## blend-tree parameter driven by the current speed factor (0 = idle, 1 = walk)
@export var walk_blend_parameter := "parameters/Blend2/blend_amount"

@export_group("Face")
## the mesh whose mouth-shape shader material is swapped for expressions
## (auto-found among the descendants if left unset)
@export var mouth_mesh: MeshInstance3D
## maps an expression name to the mouth-shape texture the mouth quad displays
@export var facial_expressions: Dictionary = _DEFAULT_EXPRESSIONS

const _MOUTH_DIR := "res://samples/shared/art/Character/mouth/"
const _DEFAULT_EXPRESSIONS := {
	"neutral": _MOUTH_DIR + "MouthShape-Smile-X.png",
	"smiling": _MOUTH_DIR + "MouthShape-Smile-A.png",
	"angry": _MOUTH_DIR + "MouthShape-Frown-D.png",
	"sad": _MOUTH_DIR + "MouthShape-Frown-A.png",
	"surprised": _MOUTH_DIR + "MouthShape-Frown-X.png",
}

## the thing this character should turn to look at (e.g. the player they're
## speaking to). when null, the character faces its last movement direction.
var look_target: Node3D

var mode := Mode.PLAYER_CONTROLLED
var current_speed_factor := 0.0
var is_alive := true

var _target_facing: Vector3 = Vector3.FORWARD
var _smoothed_speed := 0.0
var _speed_change := 0.0
var _last_grounded_position: Vector3
var _path_index := -1
var _path_wait_time := 0.0
var _path_paused := false
var _current_interactable: Node = null
var _move_id := 0
var _move_return_mode := Mode.PLAYER_CONTROLLED
var _move_return_look: Node3D
var _mouth_material: ShaderMaterial
var _mouth_surface := -1
var _expression_cache: Dictionary = {}


func _ready() -> void:
	if animation_tree == null:
		animation_tree = get_node_or_null(^"AnimationTree")
	_setup_mouth()
	# The pill model's art faces +Z, so +Z (basis.z) is "forward".
	_target_facing = global_transform.basis.z
	_last_grounded_position = global_position
	if is_player_controlled:
		add_to_group(&"player")
	elif follow_path != null and follow_path.count() >= 2:
		_begin_path()


## Snaps the character to the start of its path, facing the next waypoint, and
## switches into path-following mode.
func _begin_path() -> void:
	global_position = follow_path.world_position(0)
	var heading := follow_path.world_position(1) - global_position
	heading.y = 0.0
	if heading.length() > 0.001:
		_target_facing = heading.normalized()
		look_at(global_position - _target_facing, Vector3.UP)
	_path_index = 0
	_path_wait_time = 0.0
	mode = Mode.PATH_FOLLOWING


func _physics_process(delta: float) -> void:
	if mode == Mode.PLAYER_CONTROLLED and is_player_controlled:
		_apply_player_input(delta)
	elif mode == Mode.PATH_FOLLOWING:
		_apply_path_movement(delta)
	else:
		_apply_idle(delta)

	_update_facing(delta)
	_drive_animation()

	if is_player_controlled and mode == Mode.PLAYER_CONTROLLED:
		_update_interaction()

	# Remember the last solid ground and warp back if we fall off the world.
	if is_player_controlled:
		if is_on_floor():
			_last_grounded_position = global_position
		elif global_position.y < out_of_bounds_y:
			global_position = _last_grounded_position
			velocity = Vector3.ZERO


func _apply_player_input(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var desired := Vector3(input.x, 0.0, input.y)

	var raw_speed := 0.0
	if desired.length() > 0.01:
		raw_speed = minf(desired.length(), 1.0) * speed
		_target_facing = desired.normalized()

	# Smoothly approach the desired speed, easing in and out.
	var smoothing := acceleration if raw_speed > _smoothed_speed else deceleration
	_smoothed_speed = _smooth_damp(_smoothed_speed, raw_speed, smoothing, delta)

	var horizontal := _target_facing * _smoothed_speed if desired.length() > 0.01 else Vector3.ZERO
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	_apply_gravity(delta)
	move_and_slide()

	current_speed_factor = clampf(_smoothed_speed / speed, 0.0, 1.0)


## Critically-damped approach to a target value, giving a smooth ease in and
## out of movement without overshoot.
func _smooth_damp(current: float, target: float, smooth_time: float, delta: float) -> float:
	smooth_time = maxf(0.0001, smooth_time)
	var omega := 2.0 / smooth_time
	var x := omega * delta
	var damp := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := current - target
	var original_target := target
	var temp := (_speed_change + omega * change) * delta
	_speed_change = (_speed_change - omega * temp) * damp
	var output := (current - change) + (change + temp) * damp
	# Don't overshoot the target.
	if (original_target - current > 0.0) == (output > original_target):
		output = original_target
		_speed_change = (output - original_target) / delta
	return output


func _apply_idle(delta: float) -> void:
	# Externally-controlled characters report their own speed factor (move_to sets
	# it each frame); here we just keep them grounded. A path character paused to
	# speak has no such driver, so ease its walk blend down to a stop.
	velocity.x = 0.0
	velocity.z = 0.0
	_apply_gravity(delta)
	move_and_slide()
	if _path_paused:
		_smoothed_speed = _smooth_damp(_smoothed_speed, 0.0, deceleration, delta)
		current_speed_factor = clampf(_smoothed_speed / speed, 0.0, 1.0)
	elif mode != Mode.EXTERNALLY_CONTROLLED:
		current_speed_factor = 0.0


func _apply_path_movement(delta: float) -> void:
	if follow_path == null or follow_path.count() < 1 or _path_index < 0:
		_apply_idle(delta)
		return

	# Pausing at a waypoint: stand still and run down the wait timer.
	if _path_wait_time > 0.0:
		_path_wait_time -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		_smoothed_speed = _smooth_damp(_smoothed_speed, 0.0, deceleration, delta)
		_apply_gravity(delta)
		move_and_slide()
		current_speed_factor = clampf(_smoothed_speed / speed, 0.0, 1.0)
		return

	var to_target := follow_path.world_position(_path_index) - global_position
	to_target.y = 0.0

	if to_target.length() <= path_destination_tolerance:
		# Reached this waypoint; wait out its own delay, then aim at the next one.
		_path_wait_time = follow_path.delay(_path_index)
		_path_index = (_path_index + 1) % follow_path.count()
		return

	_target_facing = to_target.normalized()
	_smoothed_speed = _smooth_damp(_smoothed_speed, speed, acceleration, delta)
	var horizontal := _target_facing * _smoothed_speed
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	_apply_gravity(delta)
	move_and_slide()
	current_speed_factor = clampf(_smoothed_speed / speed, 0.0, 1.0)


func _apply_gravity(_delta: float) -> void:
	# Falling pushes down at a constant rate rather than integrating gravity;
	# these short drops don't need real acceleration. While grounded a light
	# stick force is enough - a full-strength push makes the capsule pop against
	# overlapping collision faces (walls meeting the ground plane).
	if not apply_gravity:
		velocity.y = 0.0
	elif is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y = -gravity


func _update_facing(delta: float) -> void:
	if not is_alive:
		return
	var desired := _get_facing_direction()
	if desired.length() < 0.001:
		return

	var current := global_transform.basis.z
	var max_step := deg_to_rad(turn_speed) * delta
	var angle := current.signed_angle_to(desired, Vector3.UP)
	var step := clampf(angle, -max_step, max_step)
	if absf(step) > 0.00001:
		rotate_y(step)


func _get_facing_direction() -> Vector3:
	if look_target != null:
		var to_target := look_target.global_position - global_position
		to_target.y = 0.0
		if to_target.length() > 0.001:
			return to_target.normalized()
	return _target_facing


func _drive_animation() -> void:
	if animation_tree != null:
		animation_tree.set(walk_blend_parameter, current_speed_factor)


# ---------------------------------------------------------------------------
# Face
# ---------------------------------------------------------------------------

## Sets the character's facial expression by swapping the mouth quad's shape
## texture. Names come from [member facial_expressions], e.g. "neutral",
## "angry", "smiling".
func set_facial_expression(expression: String) -> void:
	if _mouth_material == null:
		return
	if not facial_expressions.has(expression):
		push_warning("SimpleCharacter: unknown facial expression '%s'" % expression)
		return
	var texture := _expression_texture(expression)
	if texture != null:
		_mouth_material.set_shader_parameter("Texture", texture)


func _setup_mouth() -> void:
	if mouth_mesh == null:
		mouth_mesh = _find_mouth_mesh(self)
	if mouth_mesh == null:
		return
	# Duplicate the mouth material so each character animates its own mouth.
	var source := mouth_mesh.get_active_material(_mouth_surface) as ShaderMaterial
	if source == null:
		return
	_mouth_material = source.duplicate() as ShaderMaterial
	mouth_mesh.set_surface_override_material(_mouth_surface, _mouth_material)


func _expression_texture(expression: String) -> Texture2D:
	if _expression_cache.has(expression):
		return _expression_cache[expression]
	var value: Variant = facial_expressions[expression]
	var texture: Texture2D = value if value is Texture2D else load(value)
	_expression_cache[expression] = texture
	return texture


## Finds the mesh + surface whose material drives the mouth shader, recording
## the surface index in [member _mouth_surface].
func _find_mouth_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var count := mesh.mesh.get_surface_count() if mesh.mesh != null else 0
		for surface in count:
			var material := mesh.get_active_material(surface)
			if material is ShaderMaterial and (material as ShaderMaterial).get_shader_parameter("Mouth_Colour") != null:
				_mouth_surface = surface
				return mesh
	for child in node.get_children():
		var found := _find_mouth_mesh(child)
		if found != null:
			return found
	return null


# ---------------------------------------------------------------------------
# External control
# ---------------------------------------------------------------------------

## Walks the character to [param target_position] over time. Awaitable: yields
## until the destination is reached (or the node leaves the tree). A newer
## move_to supersedes a walk in flight, and a walk abandons itself if something
## else (say, an interaction ending) takes the mode back mid-stride - it must
## not restore a stale mode afterwards.
func move_to(target_position: Vector3) -> void:
	if global_position.distance_to(target_position) <= 0.0001:
		return

	_move_id += 1
	var walk := _move_id
	if mode != Mode.EXTERNALLY_CONTROLLED:
		_move_return_mode = mode
		_move_return_look = look_target
	look_target = null
	mode = Mode.EXTERNALLY_CONTROLLED

	while global_position.distance_to(target_position) > 0.05 and is_inside_tree():
		if walk != _move_id:
			return
		if mode != Mode.EXTERNALLY_CONTROLLED:
			current_speed_factor = 0.0
			return
		var to_target := target_position - global_position
		to_target.y = 0.0
		if to_target.length() > 0.001:
			_target_facing = to_target.normalized()
		var step := speed * get_physics_process_delta_time()
		global_position = global_position.move_toward(
			Vector3(target_position.x, global_position.y, target_position.z), step)
		current_speed_factor = 1.0
		await get_tree().physics_frame

	if walk != _move_id:
		return
	current_speed_factor = 0.0
	if mode == Mode.EXTERNALLY_CONTROLLED:
		look_target = _move_return_look
		mode = _move_return_mode


## True if this character has a path to roam.
func has_path() -> bool:
	return follow_path != null and follow_path.count() >= 2


## Stops the character roaming so it can stand and speak, without losing where
## it was on the path.
func pause_path_movement() -> void:
	_path_paused = true
	mode = Mode.EXTERNALLY_CONTROLLED


## Resumes roaming from the waypoint the pause interrupted.
func resume_path_movement() -> void:
	_path_paused = false
	mode = Mode.PATH_FOLLOWING


func is_path_paused() -> bool:
	return _path_paused


## Yarn command `<<pause_path_movement Name>>` (the roaming chatter pauses on
## every line).
func _yarn_command_pause_path_movement() -> void:
	if not has_path():
		push_error("SimpleCharacter '%s' is not following a path" % name)
		return
	pause_path_movement()


## Yarn command `<<resume_path_movement Name>>`: resumes roaming after a line.
func _yarn_command_resume_path_movement() -> void:
	if not has_path():
		push_error("SimpleCharacter '%s' is not following a path" % name)
		return
	resume_path_movement()


func set_look_direction(direction: Vector3, immediate: bool = false) -> void:
	if direction.length() < 0.001:
		return
	_target_facing = direction.normalized()
	if immediate:
		# +Z is forward, so aim -Z away from the target to face it.
		look_at(global_position - _target_facing, Vector3.UP)


# ---------------------------------------------------------------------------
# Interaction (player only)
# ---------------------------------------------------------------------------

func _update_interaction() -> void:
	var sample_point := global_transform * interaction_offset
	var nearest: Node = null
	var nearest_distance := interaction_radius

	for interactable in get_tree().get_nodes_in_group(&"interactable"):
		if interactable == self or not interactable is Node3D:
			continue
		if interactable.has_method(&"can_interact") and not interactable.can_interact():
			continue
		var distance := sample_point.distance_to((interactable as Node3D).global_position)
		if distance <= nearest_distance:
			nearest = interactable
			nearest_distance = distance

	if nearest != _current_interactable:
		if _current_interactable != null and is_instance_valid(_current_interactable):
			_current_interactable.set_current(false)
		_current_interactable = nearest
		if _current_interactable != null:
			_current_interactable.set_current(true)

	if _current_interactable != null and Input.is_action_just_pressed(&"interact"):
		var target := _current_interactable
		_current_interactable.set_current(false)
		_current_interactable = null
		_run_interaction(target)


func _run_interaction(target: Node) -> void:
	var previous_mode := mode
	var previous_look := look_target
	mode = Mode.INTERACT
	# Turn to face whoever we're interacting with, if the interactable asks.
	if target.get(&"turns_to_interactor"):
		look_target = target as Node3D
	await target.interact(self)
	if not is_inside_tree():
		return
	# Wait a frame so the input that ended the dialogue can't immediately start
	# a new interaction.
	await get_tree().process_frame
	if is_inside_tree():
		mode = previous_mode
		look_target = previous_look
