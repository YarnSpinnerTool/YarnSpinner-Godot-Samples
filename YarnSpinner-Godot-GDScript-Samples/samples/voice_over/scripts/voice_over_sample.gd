# This Source Code is subject to the terms of the LICENSE.md file
# located in the root of this project.

extends Control
## main script for the voice over sample using godot's localisation.
## demonstrates voice over with TranslationServer integration.

@export var dialogue_runner: YarnDialogueRunner
@export var language_menu: OptionButton
@export var start_button: Button

## locale codes (godot format), in the same order as the language menu
@export var locales: PackedStringArray = []


func _ready() -> void:
	# Voice-over audio: point the runner at the base-language (en) files.
	# The other locales come from Godot's translation remaps, and the line
	# text comes from real .translation resources which are both registered in
	# Project Settings > Localization.
	dialogue_runner.set_audio_base_path("res://samples/voice_over/dialogue/audio/en/")

	# set initial locale
	_set_language(0)


func _set_language(index: int) -> void:
	language_menu.select(index)
	TranslationServer.set_locale(locales[index])
	print("Language set to: %s (%s)" % [language_menu.get_item_text(index), locales[index]])


func _on_start_pressed() -> void:
	start_button.visible = false
	language_menu.visible = false
	dialogue_runner.start_dialogue()


func _on_language_selected(index: int) -> void:
	_set_language(index)


func _on_dialogue_completed() -> void:
	# show UI again after dialogue ends
	start_button.visible = true
	language_menu.visible = true


func _input(event: InputEvent) -> void:
	# quick language switch with number keys (for testing)
	if event is InputEventKey and event.pressed:
		var index: int = (event as InputEventKey).keycode - KEY_1
		if index >= 0 and index < locales.size():
			_set_language(index)
