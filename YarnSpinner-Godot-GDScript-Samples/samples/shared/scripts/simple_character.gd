class_name SimpleCharacter
extends CharacterBody3D

## A small walk-around character controller shared by the 3D samples.
##
## Player-controlled movement with smoothed acceleration and turn-to-face, plus
## externally-driven movement ([method move_to]) and a look target so NPCs can
## turn to face whoever they're talking to. The walk/idle animation blend is
## driven from the current speed.

enum Mode {
	PLAYER_CONTROLLED, ## reads input each frame
	EXTERNALLY_CONTROLLED, ## driven by move_to / commands
	PATH_FOLLOWING, ## roams a looping waypoint path
	INTERACT, ## paused while interacting
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
@export var walk_blend_parameter := "parameters/Walking/blend_amount"

## blend-tree parameter driven by commands (0 = standing, 1 = floating)
@export var float_blend_parameter := "parameters/Floating/blend_amount"

@export_group("Face")
## the mesh whose mouth-shape shader material is swapped for expressions
## (auto-found among the descendants if left unset)
@export var mouth_mesh: MeshInstance3D
## Maps an eyebrow expression name to the eyebrows transition state it requests.
@export var eyebrow_expressions: Dictionary[String, String] = _DEFAULT_EXPRESSIONS
## Maps a mouth expression name (e.g. "smiling", "frowning") to the group of
## per-mouth-shape textures used while that expression is active.
@export var mouth_expressions: Dictionary[String, LipSyncedTextureGroup] = {}
## The mouth group selected at startup, before any [code]<<expression>>[/code].
@export var default_mouth_expression := ""

@export var eyebrows_parameter := "parameters/eyebrows/transition_request"

const _ANIMATION_PARAMS := {
	"walking": "parameters/Walking/blend_amount",
	"floating": "parameters/Floating/blend_amount",
	"head_turn_tilt": "parameters/HeadTurnTilt/blend_position",
	"side_tilt": "parameters/BlendSpace1D/blend_position",
}

# Maps named expressions to the named transitions that control the eyebrow position.
const _DEFAULT_EXPRESSIONS: Dictionary[String, String] = {
	"neutral": "neutral",
	"surprised": "out",
	"angry": "in",
	"sus": "single"
}

const _MOUTH_DIR := "res://samples/shared/art/Character/mouth/"

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
## the mouth texture group currently in use (selected by set_mouth / <<expression>>)
var _current_mouth_group: LipSyncedTextureGroup
## HeadTurnTilt is a single Vector2 blend position turn and tilt_forwar tween
## these independently and _drive_animation writes the the combined vector, so two
## overlapping head commands never overriwte each other's component.
var _head_x := 0.0
var _head_y := 0.0


func _ready() -> void:
	if animation_tree == null:
		animation_tree = get_node_or_null(^"AnimationTree")
	_setup_mouth()
	if mouth_expressions.has(default_mouth_expression):
		_current_mouth_group = mouth_expressions[default_mouth_expression]
	# Transition nodes dont reliably restore their saved state on scene load;
	# with no state selected they output nothing and the whole rig freezz
	# Request the starting states explicitly.
	if animation_tree != null:
		animation_tree.set("parameters/alive/transition_request", "alive")
		animation_tree.set(eyebrows_parameter, "neutral")
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
		velocity.y = - gravity


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
		animation_tree.set(_ANIMATION_PARAMS["head_turn_tilt"], Vector2(_head_x, _head_y))


# ---------------------------------------------------------------------------
# Face
# ---------------------------------------------------------------------------

## Sets the eyebrow expression by requesting its state on the eyebrows
## transition node. Names come from [member eyebrow_expressions]
## (e.g. "neutral", "surprised", "angry", "sus"). [param crossfade] blends
## into the new state over that many seconds (0 = instant, like Unity's
## [code]animator.Play[/code] versus [code]CrossFadeInFixedTime[/code]).
func set_eyebrows(expression: String, crossfade: float = 0.0) -> void:
	if animation_tree == null:
		return
	if not eyebrow_expressions.has(expression):
		push_warning("SimpleCharacter '%s': unknown eyebrow expression '%s'" % [name, expression])
		return
	var blend_tree := animation_tree.tree_root as AnimationNodeBlendTree
	if blend_tree != null:
		var transition := blend_tree.get_node("eyebrows") as AnimationNodeTransition
		if transition != null:
			transition.xfade_time = maxf(crossfade, 0.0)
	animation_tree.set(eyebrows_parameter, eyebrow_expressions[expression])


## Selects the active mouth texture group ("smiling", "frowning", ...) and shows
## [param mouth_shape] within it (closed by default). Lip sync then pushes
## successive shapes via [method set_mouth_shape].
func set_mouth(expression: String, mouth_shape: LipSyncedTextureGroup.MouthShape = LipSyncedTextureGroup.MouthShape.X) -> void:
	if not mouth_expressions.has(expression):
		push_warning("SimpleCharacter '%s': no mouth expression '%s'" % [name, expression])
		return
	_current_mouth_group = mouth_expressions[expression]
	set_mouth_shape(mouth_shape)


## Shows a single mouth shape within the currently-selected group. Called each
## frame by the lip-sync presenter; a no-op until a group has been selected.
func set_mouth_shape(mouth_shape: LipSyncedTextureGroup.MouthShape) -> void:
	if _mouth_material == null or _current_mouth_group == null:
		return
	var texture := _current_mouth_group.get_texture(mouth_shape)
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

# ---------------------------------------------------------------------------
# Yarn commands (instance commands: <<turn Tom 0.5 0.5>> calls
# Tom._yarn_command_turn(0.5, 0.5)teh runner coerces the arguments to the
# declared types!)
# ---------------------------------------------------------------------------

## [code]<<set_animator_bool Name Floating true>>[/code]: the pill's Floating
## blend is a 0/1 scalar, so a bool maps straight onto it (mirrors the Unity
## sample's animator bool huzzah).
func _yarn_command_set_animator_bool(param_name: String, value: bool) -> void:
	var key := param_name.to_lower()
	if animation_tree == null or not _ANIMATION_PARAMS.has(key):
		return
	animation_tree.set(_ANIMATION_PARAMS[key], 1.0 if value else 0.0)


## [code]<<turn Name amount [time] [wait]>>[/code]: swings the head left/right.
func _yarn_command_turn(amount: float, time: float = 0.0, wait: bool = false) -> void:
	await _tween_property("_head_x", amount, time, wait)


## [code]<<tilt_forward Name amount [time] [wait]>>[/code]: nods the head.
## Positive tilts forward (down), negative back (up), matching Unity's
## Forward Tilt parameter; the blend space's y axis points the other way.
func _yarn_command_tilt_forward(amount: float, time: float = 0.0, wait: bool = false) -> void:
	await _tween_property("_head_y", -amount, time, wait)


## [code]<<tilt_side Name amount [time] [wait]>>[/code]: tilts the head sideways.
func _yarn_command_tilt_side(amount: float, time: float = 0.0, wait: bool = false) -> void:
	if animation_tree == null:
		return
	if time <= 0.0:
		animation_tree.set(_ANIMATION_PARAMS["side_tilt"], amount)
		return
	var tween := create_tween()
	tween.tween_property(animation_tree, _ANIMATION_PARAMS["side_tilt"], amount, time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if wait:
		await tween.finished


## [code]<<face Name expression [crossfade]>>[/code]: sets the eyebrow
## expression, blending over the optional crossfade time.
func _yarn_command_face(expression: String, crossfade: float = 0.0) -> void:
	set_eyebrows(expression, crossfade)


## [code]<<expression Name group>>[/code]: selects the active mouth group.
func _yarn_command_expression(expression: String) -> void:
	set_mouth(expression)


## [code]<<play_animation Name Gesture LookAround [wait]>>[/code]: fires the
## look-around anim. The pill has a single gesturethe layer/state args are
## accepted for parity with the Unity sample's command signature
func _yarn_command_play_animation(_layer: String, _state: String, wait: bool = false) -> void:
	if animation_tree == null:
		return
	animation_tree.set("parameters/Gesture_LookAround/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if wait:
		await get_tree().process_frame
		while is_inside_tree() and animation_tree.get("parameters/Gesture_LookAround/active"):
			await get_tree().process_frame


## Tweens a float property of this node to [param target] over [param time],
## optionally awaiting completion. Used for the head components so overlapping
## turn/tilt commands never fight over the shared HeadTurnTilt vector.
func _tween_property(property: String, target: float, time: float, wait: bool) -> void:
	if time <= 0.0:
		set(property, target)
		return
	var tween := create_tween()
	tween.tween_property(self, NodePath(property), target, time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if wait:
		await tween.finished
