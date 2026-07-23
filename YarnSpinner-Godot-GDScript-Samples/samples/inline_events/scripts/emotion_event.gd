extends YarnActionMarkupHandlerNode

## Recolours a character mid-line as [emotion="..."] markers are revealed.
## On prepare it reads the line's [character name="X"] to find the speaker, then
## collects every [emotion="..."] marker by character position. As the
## typewriter reaches each marker the speaker's appearance is swapped, and an
## angry change holds for a brief beat to let it land.

## used to restore the speaker's look if the dialogue is stopped mid-emotion
@export var dialogue_runner: YarnDialogueRunner

const _PAUSE_SECONDS := 0.3

@export var emotion_presets: Dictionary[String, EmotionPreset] = {}
@export var default_emotion := "neutral"

var _appearance: CharacterAppearance
var _character: SimpleCharacter
## character position -> emotion key
var _emotions: Dictionary[int, String] = {}
## whoever was last left in a non-neutral emotion (they may no longer be the
## current line's speaker by the time the dialogue is stopped)
var _dirty_character: SimpleCharacter
var _dirty_appearance: CharacterAppearance


func _ready() -> void:
	if dialogue_runner != null:
		dialogue_runner.dialogue_cancelled.connect(_on_dialogue_cancelled)


## A stopped dialogue can land mid-emotion; don't leave the speaker stuck angry.
func _on_dialogue_cancelled() -> void:
	var preset = emotion_presets.get(default_emotion) as EmotionPreset

	if _dirty_character != null and is_instance_valid(_dirty_character):
		_dirty_character.set_eyebrows(preset.eyebrows)
		_dirty_character.set_mouth(preset.mouth)
	if _dirty_appearance != null and is_instance_valid(_dirty_appearance):
		_dirty_appearance.set_appearance(preset.base, preset.fade)
	_dirty_character = null
	_dirty_appearance = null


func on_prepare_for_line(line: Variant, _text_control: Control = null) -> void:
	_appearance = null
	_emotions = {}

	var yarn_line := line as YarnLine
	if yarn_line == null:
		return

	# The [character] attribute is folded into character_name during line
	# processing, so read the speaker from there rather than the markup.
	var character_name := yarn_line.character_name
	if character_name.is_empty():
		push_warning("EmotionEvent: line has no character")
		return

	var target := _find_node_named(character_name)
	if target == null:
		push_warning("EmotionEvent: scene has no one called %s" % character_name)
		return
	_appearance = _find_appearance(target)
	_character = target as SimpleCharacter

	for attribute in yarn_line.markup_attributes:
		if attribute.name != "emotion":
			continue
		var emotion := attribute.try_get_string_property("emotion")
		if not emotion.is_empty():
			_emotions[attribute.position] = emotion


func on_character_will_appear(
	character_index: int,
	_line: Variant,
	_cancellation_token: Variant = null
) -> Signal:
	if not _emotions.has(character_index):
		return Signal()

	var emotion: String = _emotions[character_index]

	var preset = emotion_presets.get(emotion) as EmotionPreset

	if emotion == "neutral":
		_dirty_character = null
		_dirty_appearance = null
	else:
		_dirty_character = _character
		_dirty_appearance = _appearance

	if _character != null:
		_character.set_eyebrows(preset.eyebrows)
		_character.set_mouth(preset.mouth)

	if _appearance != null:
		_appearance.set_appearance(preset.base, preset.fade)
		if emotion != default_emotion:
			# Hold a brief moment after becoming angry to make the change clear.
			return get_tree().create_timer(_PAUSE_SECONDS).timeout
	return Signal()


func _find_node_named(node_name: String) -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)


func _find_appearance(node: Node) -> CharacterAppearance:
	for child in node.get_children():
		if child is CharacterAppearance:
			return child
	return null
