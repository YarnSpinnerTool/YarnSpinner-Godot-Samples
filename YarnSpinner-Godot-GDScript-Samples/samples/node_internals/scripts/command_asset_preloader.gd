class_name CommandAssetPreloader
extends Node

## Demonstrates inspecting a compiled Yarn program to preload the assets a
## node's commands will need. The interesting work happens in
## preload_command_assets: it walks a node's instructions, picks out the
## RunCommand ones, and collects the asset named by each set_background,
## set_music and character_avatar command. Nothing is actually loaded here, we
## just record the names into sets and simulate a slow load the first time.

## the runner whose compiled program we introspect; falls back to the first
## runner found in the scene
@export var dialogue_runner: YarnDialogueRunner
## the node whose commands we preload the assets for
@export var preload_node_name: String = "commands"

## our "preloaded" assets: a name maps to true once it has been "loaded"
var _backgrounds: Dictionary = {}
var _music: Dictionary = {}
var _avatars: Dictionary = {}


func _ready() -> void:
	if dialogue_runner == null:
		for runner in get_tree().get_nodes_in_group(&"yarn_dialogue_runner"):
			dialogue_runner = runner
			break
	if dialogue_runner == null:
		dialogue_runner = _find_runner(get_tree().current_scene)

	# Register all five as global commands (no target node). They aren't named
	# _yarn_command_* so the runner's auto-discovery won't also register them
	# as target-taking instance commands.
	# Deferred so the runner has built its library first.
	call_deferred("_register_commands")


func _register_commands() -> void:
	if dialogue_runner == null:
		return
	var library := dialogue_runner.get_library()
	var handlers := {
		"preload_command_assets": _preload_command_assets,
		"clear_preload": _clear_preload,
		"set_background": _set_background,
		"set_music": _set_music,
		"character_avatar": _character_avatar,
	}
	for command_name: String in handlers:
		if not library.has_command(command_name):
			dialogue_runner.add_command(command_name, handlers[command_name])


# this command does the actual "preloading". it reaches into the compiled
# program, walks every instruction in the target node, and for each RunCommand
# instruction works out whether it's one of the asset commands we care about. if
# it is, the command's argument tells us which asset to "load". we don't load
# anything for real, we just store the name, but the principle is the same. doing
# this through a command means the writer controls when the load happens, though
# you could just as easily do it at scene load or any other convenient time.
func _preload_command_assets() -> void:
	var node := _get_node_to_preload()
	if node == null:
		return

	for instruction in node.instructions:
		# the vast majority of instructions are RunLine; we only want commands
		if instruction.opcode != YarnInstruction.OpCode.RUN_COMMAND:
			continue

		# split the command text the same way the runner does at dispatch
		var elements := YarnCommandParser.parse(instruction.command_text)

		# every command we care about takes exactly one argument, so anything
		# else can be skipped (a real game might handle these cases per command)
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


# clears the cached "assets" so the next run "loads" everything afresh
func _clear_preload() -> void:
	_backgrounds.clear()
	_music.clear()
	_avatars.clear()


# the next three commands represent the work that actually needs an asset. the
# first time a given asset is seen we pretend to load it, pausing for a second;
# after that it's already cached and happens instantly. returning the timer's
# timeout signal makes the runner await the "load" before continuing.
func _set_background(background_asset: String) -> Variant:
	return await _ensure_loaded(_backgrounds, background_asset, "\"setting\" the background to be: %s")


func _set_music(music_asset: String) -> Variant:
	return await _ensure_loaded(_music, music_asset, "\"setting\" the music to be: %s")


func _character_avatar(character_name: String) -> Variant:
	return await _ensure_loaded(_avatars, character_name, "\"showing\" the avatar for: %s")


func _ensure_loaded(cache: Dictionary, asset: String, done_message: String) -> Variant:
	if not cache.has(asset):
		cache[asset] = true
		push_warning("%s is not already \"loaded\", pretending to do that now" % asset)
		await get_tree().create_timer(1.0).timeout
	else:
		print("%s has already been \"loaded\"" % asset)
	print(done_message % asset)
	return null


func _get_node_to_preload() -> YarnNode:
	if dialogue_runner == null or dialogue_runner.yarn_project == null:
		return null
	var program := dialogue_runner.yarn_project.get_program()
	if program == null:
		return null
	return program.get_node(preload_node_name)


func _find_runner(node: Node) -> YarnDialogueRunner:
	if node == null:
		return null
	if node is YarnDialogueRunner:
		return node
	for child in node.get_children():
		var found := _find_runner(child)
		if found != null:
			return found
	return null
