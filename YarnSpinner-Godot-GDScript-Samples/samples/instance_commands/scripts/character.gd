# Character class with Yarn Spinner instance commands.
# Commands defined here are called directly on the character node.
# e.g., <<move mae center>> calls mae._yarn_command_move("center")

extends Node2D

## Movement speed in pixels per second
@export var move_speed := 200.0

## The character's display color
@export var character_color := Color.WHITE:
	set(value):
		character_color = value
		queue_redraw()

## Character radius for drawing
@export var radius := 30.0

var _look_direction := Vector2.ZERO
var _start_position: Vector2
var _start_color: Color


func _ready() -> void:
	_start_position = position
	_start_color = character_color
	queue_redraw()


func reset() -> void:
	position = _start_position
	character_color = _start_color
	_look_direction = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	# Draw a colored circle
	draw_circle(Vector2.ZERO, radius, character_color)
	# Draw a darker outline
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, character_color.darkened(0.3), 3.0)
	# Draw eyes to show facing direction
	var eye_offset := Vector2(10, -8)
	var pupil_offset := _look_direction * 3.0
	draw_circle(eye_offset, 5, Color.WHITE)
	draw_circle(eye_offset + pupil_offset, 2, Color.BLACK)
	draw_circle(Vector2(-eye_offset.x, eye_offset.y), 5, Color.WHITE)
	draw_circle(Vector2(-eye_offset.x, eye_offset.y) + pupil_offset, 2, Color.BLACK)


# =============================================================================
# YARN INSTANCE COMMANDS
# =============================================================================
# These methods follow the _yarn_command_* naming convention.
# The dialogue runner registers them automatically, so they can be called from
# Yarn with <<command_name target args>> syntax.

## Moves this character to a destination node.
## Usage in Yarn: <<move mae center>>
## Returns a Signal so dialogue waits for movement to complete.
func _yarn_command_move(destination: String) -> Signal:
	var target := _find_destination(destination)
	if target == null:
		push_warning("Character '%s': destination '%s' not found" % [name, destination])
		return get_tree().process_frame

	# Calculate movement duration based on distance and speed
	var distance := position.distance_to(target.position)
	var duration := distance / move_speed

	# Tween to the destination
	var tween := create_tween()
	tween.tween_property(self, "position", target.position, duration)

	print("Character '%s' moving to '%s' (%.1f pixels, %.1fs)" % [name, destination, distance, duration])
	return tween.finished


## Makes this character bounce (jump up and down).
## Usage in Yarn: <<bounce bob>>
## Note: We use "bounce" not "jump" because <<jump>> is a built-in Yarn command.
## Returns a Signal so dialogue waits for the bounce to complete.
func _yarn_command_bounce() -> Signal:
	var tween := create_tween()
	var start_pos := position
	tween.tween_property(self, "position", start_pos + Vector2(0, -50), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", start_pos, 0.15).set_ease(Tween.EASE_IN)

	print("Character '%s' jumping!" % name)
	return tween.finished


## Changes this character's color.
## Usage in Yarn: <<set_color mae red>>
## Happens instantly, no wait.
func _yarn_command_set_color(color_name: String) -> void:
	var new_color := _parse_color(color_name)
	character_color = new_color
	print("Character '%s' color changed to %s" % [name, color_name])


## Makes this character face another character or waypoint.
## Usage in Yarn: <<look_at mae bob>>
func _yarn_command_look_at(target_name: String) -> void:
	var target := _find_destination(target_name)
	if target == null:
		push_warning("Character '%s': can't face '%s' - not found" % [name, target_name])
		return

	_look_direction = (target.global_position - global_position).normalized()
	queue_redraw()

	print("Character '%s' now facing '%s'" % [name, target_name])


# =============================================================================
# HELPER METHODS
# =============================================================================

func _find_destination(destination_name: String) -> Node2D:
	# Try to find the destination node in the scene
	var root := get_tree().current_scene if get_tree().current_scene != null else owner
	if root == null:
		return null

	# Try direct lookup first
	var target := root.get_node_or_null(destination_name)
	if target is Node2D:
		return target

	# Try recursive search
	return _find_node_recursive(root, destination_name)


func _find_node_recursive(node: Node, target_name: String) -> Node2D:
	if node.name == target_name and node is Node2D:
		return node
	for child in node.get_children():
		var found := _find_node_recursive(child, target_name)
		if found != null:
			return found
	return null


func _parse_color(color_name: String) -> Color:
	match color_name.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"purple", "magenta": return Color.MAGENTA
		"cyan": return Color.CYAN
		"orange": return Color.ORANGE
		"pink": return Color.HOT_PINK
		"white": return Color.WHITE
		"black": return Color.BLACK
		_:
			# Try to parse as hex
			if color_name.begins_with("#"):
				return Color.html(color_name)
			return Color.WHITE
