class_name TimeoutOptionsPresenter
extends YarnDialoguePresenter

## A custom options presenter that auto-selects an option when a countdown bar
## runs out.
##
## Option metadata drives the timeout mode:
##   #default  - a visible option auto-selected on timeout.
##   #fallback - a hidden option auto-selected on timeout (others stay visible).
## The [code]<<auto_opt>>[/code] command switches to "last highlighted" mode,
## where whichever option the player last focused is auto-selected on timeout.
## With no tags and no command the group behaves like a normal options list
## (no timer).

const VISIBLE_DEFAULT := "default"
const HIDDEN_FALLBACK := "fallback"

enum TimeoutMode { NONE, HIDDEN_FALLBACK, VISIBLE_DEFAULT, LAST_HIGHLIGHTED }

## seconds before the countdown auto-selects an option
@export var auto_select_duration: float = 10.0
## seconds to fade the options UI in before the countdown starts
@export var fade_up_duration: float = 0.25
## seconds to fade the options UI out after a selection
@export var fade_down_duration: float = 0.1
## container the option buttons are added to
@export var options_container: Container
## the countdown bar shown while a timed group is up
@export var timeout_bar: TimeoutBar

var _options: Array[YarnOption] = []
var _buttons: Array[Button] = []
var _last_highlighted_index: int = -1
var _selected_index: int = -1
var _is_showing := false
var _auto_opt_armed := false
var _command_registered := false

signal _selection_made(index: int)


func _ready() -> void:
	if options_container == null:
		for child in get_children():
			if child is Container:
				options_container = child
				break


func on_dialogue_started() -> void:
	# Register the auto_opt command once the runner is wired up.
	if not _command_registered and dialogue_runner != null:
		dialogue_runner.add_command("auto_opt", _arm_last_highlighted)
		_command_registered = true
	_set_presenter_visible(false)
	_clear_buttons()


func on_dialogue_completed() -> void:
	_set_presenter_visible(false)
	var was_showing := _is_showing
	_is_showing = false
	_auto_opt_armed = false
	if timeout_bar != null:
		timeout_bar.cancel()
	_clear_buttons()
	if was_showing:
		_selection_made.emit(-1)


## Yarn command [code]<<auto_opt>>[/code]: arm last-highlighted mode for the
## next option group. Registered on the runner in [method on_dialogue_started].
func _arm_last_highlighted() -> void:
	_auto_opt_armed = true


func run_options(options: Array[YarnOption], _token: YarnCancellationToken = null) -> int:
	_options = options
	_last_highlighted_index = -1
	_selected_index = -1
	_is_showing = true

	var mode := _resolve_mode()
	var default_index := _find_default_index(mode)

	# Incompatible timeout configurations are an authoring error, so we
	# decline to handle the group.
	if not _is_mode_valid(mode, default_index):
		_auto_opt_armed = false
		_is_showing = false
		return -1

	_clear_buttons()
	_create_buttons(mode, default_index)

	if timeout_bar != null:
		timeout_bar.visible = mode != TimeoutMode.NONE
		if mode != TimeoutMode.NONE:
			timeout_bar.reset()

	_set_presenter_visible(true)

	# Focus the first selectable button so "last highlighted" has a sensible
	# starting value and keyboard users can act immediately.
	for button in _buttons:
		if not button.disabled:
			button.grab_focus()
			break

	# Fade the UI up before the countdown starts.
	await _fade_presenter_alpha(0.0, 1.0, fade_up_duration)

	if mode != TimeoutMode.NONE and timeout_bar != null:
		_run_timeout(mode, default_index)

	# A click can land while the fade-up above is still running; _select has
	# then already emitted (and recorded) the choice, so don't await an
	# emission that has been and gone, same as the built-in presenter.
	var index: int = _selected_index
	if index < 0:
		index = await _selection_made

	_is_showing = false
	_auto_opt_armed = false
	if timeout_bar != null:
		timeout_bar.cancel()
	await _fade_presenter_alpha(1.0, 0.0, fade_down_duration)
	_set_presenter_visible(false)
	_clear_buttons()
	return index


# ---------------------------------------------------------------------------
# Mode resolution
# ---------------------------------------------------------------------------

## Metadata for an option's line. Falls back to the compiled program's line
## metadata table when the option carries none itself.
func _metadata_for(option: YarnOption) -> PackedStringArray:
	if not option.metadata.is_empty():
		return option.metadata
	if dialogue_runner != null and dialogue_runner.yarn_project != null:
		var program: YarnProgram = dialogue_runner.yarn_project.get_program()
		if program != null:
			return program.get_line_metadata(option.line_id)
	return option.metadata


func _resolve_mode() -> TimeoutMode:
	if _auto_opt_armed:
		return TimeoutMode.LAST_HIGHLIGHTED
	for option in _options:
		if not option.is_available:
			continue
		for tag in _metadata_for(option):
			if tag == HIDDEN_FALLBACK:
				return TimeoutMode.HIDDEN_FALLBACK
			if tag == VISIBLE_DEFAULT:
				return TimeoutMode.VISIBLE_DEFAULT
	return TimeoutMode.NONE


func _find_default_index(mode: TimeoutMode) -> int:
	if mode != TimeoutMode.HIDDEN_FALLBACK and mode != TimeoutMode.VISIBLE_DEFAULT:
		return -1
	var tag := HIDDEN_FALLBACK if mode == TimeoutMode.HIDDEN_FALLBACK else VISIBLE_DEFAULT
	for i in _options.size():
		var option := _options[i]
		if option.is_available and tag in _metadata_for(option):
			return i
	return -1


## Counts available options carrying a timeout tag, to detect the "more than
## one default" authoring error.
func _count_tagged() -> int:
	var count := 0
	for option in _options:
		if not option.is_available:
			continue
		var metadata := _metadata_for(option)
		if VISIBLE_DEFAULT in metadata or HIDDEN_FALLBACK in metadata:
			count += 1
	return count


func _is_mode_valid(mode: TimeoutMode, default_index: int) -> bool:
	match mode:
		TimeoutMode.HIDDEN_FALLBACK, TimeoutMode.VISIBLE_DEFAULT:
			if _count_tagged() != 1:
				push_error("timeout options: encountered more than one option with timeout tags")
				return false
			if default_index < 0:
				push_error("timeout options: option tagged as default but no option resolved")
				return false
		TimeoutMode.LAST_HIGHLIGHTED:
			if _count_tagged() != 0:
				push_error("timeout options: asked for last-highlighted but options are also tagged")
				return false
	return true


# ---------------------------------------------------------------------------
# Buttons
# ---------------------------------------------------------------------------

func _create_buttons(mode: TimeoutMode, default_index: int) -> void:
	for i in _options.size():
		var option := _options[i]
		if not option.is_available:
			continue
		# Hide the fallback option's button; it can still win on timeout.
		if mode == TimeoutMode.HIDDEN_FALLBACK and i == default_index:
			continue

		var button := Button.new()
		button.text = option.get_plain_text()
		button.custom_minimum_size = Vector2(0, 80)
		button.add_theme_font_size_override("font_size", 40)

		var index := i
		button.pressed.connect(func(): _select(index))
		button.focus_entered.connect(func(): _last_highlighted_index = index)

		if options_container != null:
			options_container.add_child(button)
		else:
			add_child(button)
		_buttons.append(button)


func _clear_buttons() -> void:
	for button in _buttons:
		if is_instance_valid(button):
			button.queue_free()
	_buttons.clear()


func _select(index: int) -> void:
	if not _is_showing:
		return
	if index < 0 or index >= _options.size() or not _options[index].is_available:
		return
	_is_showing = false
	_selected_index = index
	_selection_made.emit(index)


# ---------------------------------------------------------------------------
# Timeout
# ---------------------------------------------------------------------------

func _run_timeout(mode: TimeoutMode, default_index: int) -> void:
	await timeout_bar.shrink(auto_select_duration)
	# The bar emits even after cancel races; bail if a click already won.
	if not _is_showing:
		return
	var index := default_index
	if mode == TimeoutMode.LAST_HIGHLIGHTED:
		index = _last_highlighted_index
		if index < 0:
			index = _first_available_index()
	if index < 0:
		return
	_select(index)


func _first_available_index() -> int:
	for i in _options.size():
		if _options[i].is_available:
			return i
	return -1
