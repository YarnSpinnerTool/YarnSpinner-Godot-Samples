extends Node2D

@export var move_speed := 200.0

@export var character_color := Color.WHITE:
	set(value):
		character_color = value
		queue_redraw()

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
	draw_circle(Vector2.ZERO, radius, character_color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, character_color.darkened(0.3), 3.0)
	var eye_offset := Vector2(10, -8)
	var pupil_offset := _look_direction * 3.0
	draw_circle(eye_offset, 5, Color.WHITE)
	draw_circle(eye_offset + pupil_offset, 2, Color.BLACK)
	draw_circle(Vector2(-eye_offset.x, eye_offset.y), 5, Color.WHITE)
	draw_circle(Vector2(-eye_offset.x, eye_offset.y) + pupil_offset, 2, Color.BLACK)


func _yarn_command_move(destination: String) -> void:
	var target := _find_destination(destination)
	if target == null:
		push_warning("Character '%s': destination '%s' not found" % [name, destination])
		return

	var distance := position.distance_to(target.position)
	var duration := distance / move_speed

	var tween := create_tween()
	tween.tween_property(self, "position", target.position, duration)

	print("Character '%s' moving to '%s' (%.1f pixels, %.1fs)" % [name, destination, distance, duration])
	await tween.finished


func _yarn_command_bounce() -> void:
	var tween := create_tween()
	var start_pos := position
	tween.tween_property(self, "position", start_pos + Vector2(0, -50), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", start_pos, 0.15).set_ease(Tween.EASE_IN)

	print("Character '%s' jumping!" % name)
	await tween.finished


func _yarn_command_set_color(color_name: String) -> void:
	var new_color := _parse_color(color_name)
	character_color = new_color
	print("Character '%s' color changed to %s" % [name, color_name])


func _yarn_command_look_at(target_name: String) -> void:
	var target := _find_destination(target_name)
	if target == null:
		push_warning("Character '%s': can't face '%s' - not found" % [name, target_name])
		return

	_look_direction = (target.global_position - global_position).normalized()
	queue_redraw()

	print("Character '%s' now facing '%s'" % [name, target_name])


func _find_destination(destination_name: String) -> Node2D:
	var root := get_tree().current_scene if get_tree().current_scene != null else owner
	if root == null:
		return null

	var target := root.get_node_or_null(destination_name)
	if target is Node2D:
		return target

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
			if color_name.begins_with("#"):
				return Color.html(color_name)
			return Color.WHITE
