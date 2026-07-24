class_name DebugLookAtMouse
extends Node

## the character to drive; found by name if left unset
@export var character: SimpleCharacter
@export var character_name := "Tom"
@export var toggle_key: Key = KEY_F10
## how quickly the head chases the cursor (higher = snappier)
@export var chase_speed := 6.0

var _enabled := false
## true while easing the head back to centre after being switched off
var _releasing := false


func _ready() -> void:
	if character == null:
		var root := get_tree().current_scene if get_tree().current_scene != null else owner
		if root != null:
			character = root.find_child(character_name, true, false) as SimpleCharacter


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == toggle_key:
		_enabled = not _enabled
		if not _enabled:
			_releasing = true
		if _enabled:
			print("DebugLookAtMouse: ON (%s looks at the mouse; %s to stop)" % [character.name if character else "?", OS.get_keycode_string(toggle_key)])
		else:
			print("DebugLookAtMouse: OFF")
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if character == null:
		return
	# When switched off, ease the head back to centre and then stop touching it
	# entirely, so the yarn's own turn/tilt commands are never fought.
	if not _enabled:
		if not _releasing:
			return
		if absf(character._head_x) < 0.01 and absf(character._head_y) < 0.01:
			character._head_x = 0.0
			character._head_y = 0.0
			_releasing = false
			return
	var target := Vector2.ZERO
	if _enabled:
		var size := get_viewport().get_visible_rect().size
		var mouse := get_viewport().get_mouse_position()
		# mouse position -> [-1, 1] around the viewport centre;
		# x drives turn, y drives forward tilt (top of screen = look up).
		# The character faces the camera, so screen-left is their right:
		# the turn axis is mirrored to make them look toward the cursor.
		target.x = clampf(-(mouse.x / size.x * 2.0 - 1.0), -1.0, 1.0)
		target.y = clampf(-(mouse.y / size.y * 2.0 - 1.0), -1.0, 1.0)
	# ease toward the target (and back to centre when disabled), writing the
	# same fields the turn / tilt_forward yarn commands tween
	var w := clampf(chase_speed * delta, 0.0, 1.0)
	character._head_x = lerpf(character._head_x, target.x, w)
	character._head_y = lerpf(character._head_y, target.y, w)
