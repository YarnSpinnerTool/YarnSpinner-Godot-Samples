class_name CommandAssetPreloader
extends Node


@export var dialogue_runner: YarnDialogueRunner
@export var preload_node_name: String = "commands"

var _backgrounds: Dictionary = {}
var _music: Dictionary = {}
var _avatars: Dictionary = {}


func _ready() -> void:
	_register_commands()


var _commands_registered := false


func _register_commands() -> void:
	if dialogue_runner == null or _commands_registered:
		return
	_commands_registered = true
	dialogue_runner.add_command("preload_command_assets", _preload_command_assets)
	dialogue_runner.add_command("clear_preload", _clear_preload)
	dialogue_runner.add_command("set_background", _set_background)
	dialogue_runner.add_command("set_music", _set_music)
	dialogue_runner.add_command("character_avatar", _character_avatar)


func _preload_command_assets() -> void:
	var node := _get_node_to_preload()
	if node == null:
		return

	for instruction in node.instructions:
		if instruction.opcode != YarnInstruction.OpCode.RUN_COMMAND:
			continue

		var elements := YarnCommandParser.parse(instruction.command_text)

		if elements.size() != 2:
			continue

		match elements[0]:
			"set_background":
				_backgrounds[elements[1]] = true
			"set_music":
				_music[elements[1]] = true
			"character_avatar":
				_avatars[elements[1]] = true

	print("preloaded backgrounds: %s" % str(_backgrounds.keys()))
	print("preloaded music: %s" % str(_music.keys()))
	print("preloaded avatars: %s" % str(_avatars.keys()))


func _clear_preload() -> void:
	_backgrounds.clear()
	_music.clear()
	_avatars.clear()


func _set_background(background_asset: String) -> void:
	await _ensure_loaded(_backgrounds, background_asset, "\"setting\" the background to be: %s")


func _set_music(music_asset: String) -> void:
	await _ensure_loaded(_music, music_asset, "\"setting\" the music to be: %s")


func _character_avatar(character_name: String) -> void:
	await _ensure_loaded(_avatars, character_name, "\"showing\" the avatar for: %s")


func _ensure_loaded(cache: Dictionary, asset: String, done_message: String) -> void:
	if not cache.has(asset):
		cache[asset] = true
		push_warning("%s is not already \"loaded\", pretending to do that now" % asset)
		await get_tree().create_timer(1.0).timeout
	else:
		print("%s has already been \"loaded\"" % asset)
	print(done_message % asset)


func _get_node_to_preload() -> YarnNode:
	if dialogue_runner == null or dialogue_runner.yarn_project == null:
		return null
	var program := dialogue_runner.yarn_project.get_program()
	if program == null:
		return null
	return program.get_node(preload_node_name)
