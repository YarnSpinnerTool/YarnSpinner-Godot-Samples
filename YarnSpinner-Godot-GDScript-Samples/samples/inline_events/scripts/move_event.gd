extends YarnActionMarkupHandlerNode

## Walks the player mid-line as [move name="Y"] markers are revealed, and also
## registers a <<move Y>> command. On prepare it collects every
## [move name="Y"] marker by character position, resolving each Y to a scene
## marker's position. As the typewriter reaches a marker the player walks
## there; the same lookup backs the command.

## the player to move; auto-found via the "player" group if left empty
@export var player_character: SimpleCharacter
## the runner the <<move>> command is registered on
@export var dialogue_runner: YarnDialogueRunner

## character position -> world position
var _movements: Dictionary = {}

## emitted once a mid-line walk finishes, to release the paused typewriter
signal _walk_finished


func _ready() -> void:
	if player_character == null:
		var players := get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			player_character = players[0] as SimpleCharacter

	# Register a global <<move marker>> command. Done in code (rather than a
	# _yarn_command_ method) so it stays a plain command with no target
	# argument. Deferred so the runner has finished building its library first.
	call_deferred("_register_command")


func _register_command() -> void:
	if dialogue_runner != null and not dialogue_runner.get_library().has_command("move"):
		dialogue_runner.add_command("move", _command_move)


func on_prepare_for_line(line: Variant, _text_control: Control = null) -> void:
	_movements = {}

	var yarn_line := line as YarnLine
	if yarn_line == null:
		return

	for attribute in yarn_line.markup_attributes:
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
	_cancellation_token: Variant = null
) -> Signal:
	if player_character == null or not _movements.has(character_index):
		return Signal()
	# Drive the (coroutine) walk separately and pause the typewriter on a real
	# signal, as returning a coroutine's own await wouldn't surface as a Signal.
	_run_walk(_movements[character_index])
	return _walk_finished


func _run_walk(target_position: Vector3) -> void:
	await player_character.move_to(target_position)
	_walk_finished.emit()


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
	var root := get_tree().current_scene
	if root == null:
		return null
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)
