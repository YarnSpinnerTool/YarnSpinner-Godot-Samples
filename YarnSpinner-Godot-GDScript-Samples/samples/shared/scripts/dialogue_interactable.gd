class_name DialogueInteractable
extends Node3D

## Makes a character talkable: when the player is close enough and the target
## Yarn node group has salient content to run, a speaking indicator appears;
## interacting starts the dialogue.

## the Yarn node (or node group) to start when interacted with
@export var node_name: String = ""
@export var dialogue_runner: YarnDialogueRunner
## the character turns to face the interactor while talking
@export var turns_to_interactor := true
## animated in/out as this interactable becomes the player's current target
@export var speaking_indicator: Node3D

const _APPEAR := "speaking_indicator/appear"
const _DISAPPEAR := "speaking_indicator/disappear"
const _HIDDEN := "speaking_indicator/hidden"
const _HOVER := "Hover"

var is_current := false
var _indicator_player: AnimationPlayer
## the Alert model's own player, which holds the continuous bob (Hover)
var _hover_player: AnimationPlayer


func _ready() -> void:
	add_to_group(&"interactable")
	if dialogue_runner == null:
		# Fall back to the first runner in the scene.
		var runners := get_tree().get_nodes_in_group(&"yarn_dialogue_runner")
		if not runners.is_empty():
			dialogue_runner = runners[0]
	if speaking_indicator != null:
		_indicator_player = _find_player_with(speaking_indicator, _APPEAR)
		_hover_player = _find_player_with(speaking_indicator, _HOVER)
		# The bob loops continuously while the indicator is visible;
		# appear/disappear only scale it in and out.
		if _hover_player != null:
			var hover := _hover_player.get_animation(_HOVER)
			if hover != null:
				hover.loop_mode = Animation.LOOP_LINEAR
	is_current = false
	# Start hidden without animating in/out.
	if _indicator_player != null and _indicator_player.has_animation(_HIDDEN):
		_indicator_player.play(_HIDDEN)
	elif speaking_indicator != null:
		speaking_indicator.visible = false


## Whether this interactable can currently be selected: it needs a runner that
## isn't already running, and salient content available for its node group.
func can_interact() -> bool:
	if dialogue_runner == null or node_name.is_empty():
		return false
	if dialogue_runner.is_running():
		return false
	if dialogue_runner.is_node_group(node_name):
		return dialogue_runner.has_salient_content(node_name)
	return true


func set_current(value: bool) -> void:
	# Only actually highlight if we could be interacted with.
	if value and not can_interact():
		value = false
	if value == is_current:
		return
	is_current = value
	# Play the indicator's pop-in / pop-out animation.
	if _indicator_player != null:
		var clip := _APPEAR if value else _DISAPPEAR
		if _indicator_player.has_animation(clip):
			_indicator_player.play(clip)
	elif speaking_indicator != null:
		speaking_indicator.visible = value
	# Run the continuous bob only while the indicator is shown.
	if _hover_player != null and _hover_player.has_animation(_HOVER):
		if value:
			_hover_player.play(_HOVER)
		else:
			_hover_player.stop()


## Finds the descendant AnimationPlayer holding a given animation. The
## indicator's appear/disappear player and the Alert model's hover player are
## separate, so we locate each by the clip it owns; falls back to the first one.
func _find_player_with(node: Node, animation_name: String) -> AnimationPlayer:
	var fallback: AnimationPlayer = null
	var queue: Array[Node] = [node]
	while not queue.is_empty():
		var current: Node = queue.pop_front()
		for child in current.get_children():
			if child is AnimationPlayer:
				if (child as AnimationPlayer).has_animation(animation_name):
					return child
				if fallback == null:
					fallback = child
			queue.append(child)
	return fallback


## Starts the dialogue, turning to face the interactor for the duration.
func interact(interactor: Node3D) -> void:
	if not can_interact():
		return

	set_current(false)

	var character := get_parent() as SimpleCharacter
	if turns_to_interactor and character != null:
		character.look_target = interactor

	dialogue_runner.start_dialogue(node_name)
	await dialogue_runner.dialogue_completed

	if character != null and is_instance_valid(character):
		if turns_to_interactor:
			character.look_target = null
		# A stopped dialogue can end between the yarn script's pause and resume
		# commands; don't leave the character frozen off its path.
		if character.is_path_paused():
			character.resume_path_movement()
