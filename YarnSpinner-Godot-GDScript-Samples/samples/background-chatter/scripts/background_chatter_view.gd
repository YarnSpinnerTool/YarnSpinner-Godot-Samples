class_name BackgroundChatterView
extends YarnDialoguePresenter


@export_group("Timing")
@export var milliseconds_per_character: int = 75
@export var min_duration: float = 1.5
@export var delay_after_lines: float = 0.5

@export_group("Appearance")
@export var label: Label

const REFERENCE_WIDTH := 1920.0

var _font_size: int
var _box_size: Vector2
var _target: ChatterNPC
var _line_generation := 0


func _ready() -> void:
	_font_size = label.get_theme_font_size(&"font_size")
	_box_size = label.size


func _process(_delta: float) -> void:
	if label == null or not label.visible:
		return
	if _target == null or not is_instance_valid(_target):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var point := _target.chatter_point()
	if camera.is_position_behind(point):
		label.hide()
		return
	label.position = camera.unproject_position(point) - label.size * 0.5


func _fit_label() -> void:
	var scale := get_viewport().get_visible_rect().size.x / REFERENCE_WIDTH
	label.add_theme_font_size_override(&"font_size", int(_font_size * scale))
	label.size = _box_size * scale


func run_line(line: YarnLine, token: YarnCancellationToken = null) -> void:
	var speaker := line.character_name
	if speaker.is_empty():
		push_warning("BackgroundChatterView: line %s has no character name" % line.line_id)
		return

	_target = ChatterNPC.find_by_name(get_tree(), speaker)
	if _target == null:
		push_warning("BackgroundChatterView: no chatter NPC named '%s'" % speaker)
		return

	var body := line.text_without_character_name
	label.text = body
	_fit_label()
	label.visible = true

	_line_generation += 1
	_show_line(body, token, _line_generation)
	await _line_done


signal _line_done


func _show_line(body: String, token: YarnCancellationToken, generation: int) -> void:
	var duration := maxf(body.length() * milliseconds_per_character / 1000.0, min_duration)

	if not await _wait(duration, token):
		_dismiss(generation)
		return

	if generation == _line_generation:
		label.visible = false

	await _wait(delay_after_lines, token)
	_dismiss(generation)


func _wait(seconds: float, token: YarnCancellationToken) -> bool:
	var elapsed := 0.0
	while elapsed < seconds:
		if not is_inside_tree():
			return false
		if token != null and token.is_cancelled:
			return false
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return true


func _dismiss(generation: int) -> void:
	if generation != _line_generation:
		return
	if label != null:
		label.visible = false
	_target = null
	_line_done.emit()


func on_dialogue_completed() -> void:
	if label != null:
		label.visible = false
	_target = null
	_line_done.emit()
