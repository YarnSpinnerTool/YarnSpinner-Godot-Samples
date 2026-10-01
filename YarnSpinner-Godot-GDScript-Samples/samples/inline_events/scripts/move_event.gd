extends YarnActionMarkupHandlerNode

## Walks the player mid-line as [move name="Y"] markers are revealed, and also
## registers a <<move Y>> command. On prepare it collects every
## [move name="Y"] marker by character position, resolving each Y to a scene
## marker's position. As the typewriter reaches a marker the player walks
## there; the same lookup backs the command.

## the player to move
@export var player_character: SimpleCharacter
## the runner the <<move>> command is registered on
@export var dialogue_runner: YarnDialogueRunner

## character position -> world position
var _movements: Dictionary = {}

## emitted once a mid-line walk finishes, to release the paused typewriter
signal _walk_finished


func _ready() -> void:
	# Register a global <<move marker>> command. Done in code (rather than a
	# _yarn_command_ method) so it stays a plain command with no target
	# argument. Deferred so the runner has finished building its library first.
	call_deferred("_register_command")


var _command_registered := false


func _register_command() -> void:
	if dialogue_runner != null and not _command_registered:
		_command_registered = true
		dialogue_runner.add_command("move", _command_move)


func on_prepare_for_line(line: Variant, _text_control: Control = null) -> void:
	_movements = {}

	var markup := line as YarnMarkupParseResult
	if markup == null:
		return

	for attribute in markup.attributes:
		if attribute.name != "move":
			continue
		var marker_name := attribute.try_get_string_property("name")
		if marker_name.is_empty():
			continue
		var marker := _find_node_named(marker_name)
		if marker is Node3D:
			_movements[attribute.position] = (marker as Node3D).global_position


func on_character_will_appear(
	character_index: int,
	_line: Variant,
	cancellation_token: Variant = null
) -> Signal:
	if player_character == null or not _movements.has(character_index):
		return Signal()
	var token := cancellation_token as YarnCancellationToken
	if token != null and token.is_hurry_up_requested:
		return Signal()
	var target_position: Vector3 = _movements[character_index]
	var offset := player_character.global_position - target_position
	if Vector2(offset.x, offset.z).length() <= 0.05:
		return Signal()
	# Drive the (coroutine) walk separately and pause the typewriter on a real
	# signal, as returning a coroutine's own await wouldn't surface as a Signal.
	_run_walk(target_position, token)
	return _walk_finished


func _run_walk(target_position: Vector3, token: YarnCancellationToken) -> void:
	var release := func() -> void:
		_walk_finished.emit()
	if token != null:
		token.hurry_up_requested.connect(release, CONNECT_ONE_SHOT)
	await player_character.move_to(target_position)
	if token == null:
		_walk_finished.emit.call_deferred()
	elif token.hurry_up_requested.is_connected(release):
		token.hurry_up_requested.disconnect(release)
		_walk_finished.emit.call_deferred()


func on_line_display_complete() -> void:
	_movements = {}


## <<move marker>>: walks the player to the named scene marker.
func _command_move(marker_name: String) -> void:
	if player_character == null:
		return
	var marker := _find_node_named(marker_name)
	if marker is Node3D:
		await player_character.move_to((marker as Node3D).global_position)


func _find_node_named(node_name: String) -> Node:
	var root := get_tree().current_scene if get_tree().current_scene != null else owner
	if root == null:
		return null
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)
