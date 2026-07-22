class_name BackgroundChatterView
extends YarnDialoguePresenter

## A presenter for ambient conversations: each line is shown as screen-space
## text projected from a point above the speaking character, for a duration
## derived from its length, then auto-completes with no player input.
##
## The label lives on a screen-space overlay and follows the
## speaker's chatter point via the camera projection each frame, so the text
## keeps a constant on-screen size. The speaker is located by name via
## [ChatterNPC]; lines have no options, so [method run_options] stays a no-op.

@export_group("Timing")
## Display time per character of line text.
@export var milliseconds_per_character: int = 75
## Minimum display time regardless of length.
@export var min_duration: float = 1.5
## Pause after a line before the next one shows.
@export var delay_after_lines: float = 0.5

## Text metrics are authored for a 1920x1080 canvas and scaled to the viewport.
@export_group("Appearance")
@export var font_size: float = 36.0
@export var box_width: float = 353.43
@export var box_height: float = 107.77
@export var text_color := Color(1, 1, 1)

const REFERENCE_WIDTH := 1920.0

var _layer: CanvasLayer
var _label: Label
var _target: ChatterNPC
var _line_generation := 0


func _ready() -> void:
	_layer = CanvasLayer.new()
	add_child(_layer)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override(&"font_color", text_color)
	_label.visible = false
	_layer.add_child(_label)


func _process(_delta: float) -> void:
	if _label == null or not _label.visible:
		return
	if _target == null or not is_instance_valid(_target):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var point := _target.chatter_point()
	if camera.is_position_behind(point):
		_label.hide()
		return
	# Centre the fixed text box on the projected point.
	_label.position = camera.unproject_position(point) - _label.size * 0.5


## Sizes the label to the authored box (scaled to the viewport width) so the
## box stays stable while it tracks the speaker.
func _fit_label() -> void:
	var scale := get_viewport().get_visible_rect().size.x / REFERENCE_WIDTH
	_label.add_theme_font_size_override(&"font_size", int(font_size * scale))
	_label.size = Vector2(box_width, box_height) * scale


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
	_label.text = body
	_fit_label()
	_label.visible = true

	_line_generation += 1
	_show_line(body, token, _line_generation)
	await _line_done


signal _line_done


## Holds the line on screen for a length-based duration, then dismisses it and
## signals completion. Bails early if the line is cancelled (e.g. the chatter is
## interrupted by the primary conversation). The generation guard stops a
## cancelled line's timer from dismissing the line that replaced it - the
## walk-away interrupt line starts while the interrupted line's timer is still
## unwinding.
func _show_line(body: String, token: YarnCancellationToken, generation: int) -> void:
	var duration := maxf(body.length() * milliseconds_per_character / 1000.0, min_duration)

	if not await _wait(duration, token):
		_dismiss(generation)
		return

	if generation == _line_generation:
		_label.visible = false

	await _wait(delay_after_lines, token)
	_dismiss(generation)


## Waits [param seconds], returning false if cancelled before the time elapses.
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
	if _label != null:
		_label.visible = false
	_target = null
	_line_done.emit()


func on_dialogue_completed() -> void:
	# The chatter stopped (finished or was interrupted); hide any visible line
	# and release a run_line still parked on its completion.
	if _label != null:
		_label.visible = false
	_target = null
	_line_done.emit()
