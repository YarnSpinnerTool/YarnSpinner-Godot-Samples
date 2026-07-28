# This Source Code is subject to the terms of the LICENSE.md file
# located in the root of this project.

class_name ChatDialoguePresenter
extends YarnDialoguePresenter
## presents dialogue as chat bubbles in a scrolling message list, like a
## messaging app. Runs both lines and options; use it instead of the
## standard line and options presenters!

@export_group("Scenes")
## character name -> bubble scene. Lines from unlisted characters use teh
## default bubble.
@export var bubble_scenes: Dictionary[String, PackedScene] = {}
@export var default_bubble_scene: PackedScene
@export var options_button_scene: PackedScene

@export_group("Containers")
## the message list. The options container should be its last child, so
## new bubbles are inserted above the choices.
@export var bubble_container: Container
@export var options_container: Container
## scrolls to keep the newest message visible
@export var scroll_container: ScrollContainer

@export_group("Timing")
## seconds to linger on a bubble before the next line
@export var delay_after_line: float = 1.0
## clamp range for the fake "typing" time
@export var minimum_typing_delay: float = 1.0
@export var maximum_typing_delay: float = 3.0
## typing time per character of the incoming message
@export var typing_delay_per_character: float = 0.1
@export var show_typing_indicators: bool = true


func _ready() -> void:
	if scroll_container != null:
		scroll_container.get_v_scroll_bar().self_modulate.a = 0.0


func run_line(line: YarnLine, token: YarnCancellationToken = null) -> void:
	if bubble_container == null:
		push_warning("chat presenter: no bubble container")
		return

	var scene := default_bubble_scene
	if not line.character_name.is_empty() and bubble_scenes.has(line.character_name):
		scene = bubble_scenes[line.character_name]
	if scene == null:
		push_warning("chat presenter: no bubble scene for '%s'" % line.character_name)
		return

	var text := line.text_without_character_name

	if show_typing_indicators:
		var typing: ChatBubble = scene.instantiate()
		_add_to_list(typing)
		if typing.has_indicator():
			typing.show_typing()
			var typing_delay := clampf(text.length() * typing_delay_per_character,
				minimum_typing_delay, maximum_typing_delay)
			await _skippable_wait(typing_delay, token)
		typing.queue_free()

	var bubble: ChatBubble = scene.instantiate()
	_add_to_list(bubble)
	bubble.show_text(text)
	_scroll_to_latest(bubble)

	await _skippable_wait(delay_after_line, token)


func run_options(options: Array[YarnOption], token: YarnCancellationToken = null) -> int:
	if options_container == null or options_button_scene == null:
		push_warning("chat presenter: options container or button scene not set")
		return -1

	for child in options_container.get_children():
		child.queue_free()

	var selection := YarnPromise.new()
	for i in options.size():
		if not options[i].is_available:
			continue
		var button: ChatOptionButton = options_button_scene.instantiate()
		button.set_option_text(options[i].text_without_character_name)
		var index := i
		button.pressed.connect(func(): selection.settle(index))
		options_container.add_child(button)
	_scroll_to_latest(options_container)

	var on_wind_down := func() -> void:
		selection.settle(-1)
	if token != null:
		token.next_content_requested.connect(on_wind_down, CONNECT_ONE_SHOT)
		if token.is_next_content_requested:
			selection.settle(-1)

	var result: Variant = await selection.wait()

	if token != null and token.next_content_requested.is_connected(on_wind_down):
		token.next_content_requested.disconnect(on_wind_down)
	for child in options_container.get_children():
		child.queue_free()

	return int(result)


## bubbles are inserted just above the options container when it lives at
## the bottom of the message list...
func _add_to_list(bubble: Control) -> void:
	bubble_container.add_child(bubble)
	if options_container != null and options_container.get_parent() == bubble_container:
		bubble_container.move_child(bubble, options_container.get_index())


func _scroll_to_latest(item: Control) -> void:
	if scroll_container == null or item == null:
		return
	_scroll_deferred(item)


func _scroll_deferred(item: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll_container) and is_instance_valid(item):
		scroll_container.ensure_control_visible(item)


## waits, ending early if the player hurries or skips..
func _skippable_wait(seconds: float, token: YarnCancellationToken) -> void:
	if not is_inside_tree():
		return
	var remaining := seconds
	while remaining > 0.0:
		if token != null and token.is_cancelled:
			return
		await get_tree().process_frame
		if not is_inside_tree():
			return
		if not can_process():
			continue
		remaining -= get_process_delta_time()
