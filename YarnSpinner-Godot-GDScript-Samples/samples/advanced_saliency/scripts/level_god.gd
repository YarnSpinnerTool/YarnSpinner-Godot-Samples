class_name LevelGod
extends Node3D


@export var layouts: Dictionary[String, RoomLayout] = {}
@export var room_anchor: Node3D
@export var variable_storage: TheRoomVariableStorage
@export var dialogue_runner: YarnDialogueRunner

var _current_environment: Node3D
var _initial_positions: Dictionary[SimpleCharacter, Vector3] = {}


func _ready() -> void:
	if room_anchor == null:
		room_anchor = self
	if dialogue_runner != null:
		dialogue_runner.add_command("start_level", spawn_level)

	for character_name in TheRoomVariableStorage.CHARACTER_NAMES:
		var character := _find_character(character_name)
		if character != null:
			_initial_positions[character] = character.global_position


func spawn_level() -> void:
	if _current_environment != null:
		_current_environment.queue_free()
		_current_environment = null

	for character in _initial_positions:
		if is_instance_valid(character):
			character.global_position = _initial_positions[character]

	var room_name := TheRoomVariableStorage.ROOM_NAMES[variable_storage.get_room()]
	var layout: RoomLayout = layouts.get(room_name)
	if layout == null:
		push_error("level god: no layout configured for room '%s'" % room_name)
		return

	_place(_find_character(variable_storage.get_primary_name()), layout.primary)
	_place(_find_character(variable_storage.get_secondary_name()), layout.secondary)

	if layout.environment_scene != null:
		_current_environment = layout.environment_scene.instantiate()
		if room_anchor != null:
			room_anchor.add_child(_current_environment)
			_current_environment.rotate_y(PI)


func _place(character: SimpleCharacter, spawn: CharacterSpawn) -> void:
	if character == null or spawn == null:
		return
	if room_anchor != null:
		character.global_position = room_anchor.to_global(spawn.position)
		character.set_look_direction(room_anchor.global_basis * spawn.look_direction(), true)
	else:
		character.global_position = spawn.position
		character.set_look_direction(spawn.look_direction(), true)


func _find_character(character_name: String) -> SimpleCharacter:
	var scene := get_tree().current_scene if get_tree().current_scene != null else owner
	if scene == null:
		return null
	return scene.find_child(character_name, true, false) as SimpleCharacter
