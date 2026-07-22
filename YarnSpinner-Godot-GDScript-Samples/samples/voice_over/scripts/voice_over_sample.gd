# This Source Code Form is subject to the terms of the LICENSE.md file
# located in the root of this project.

extends Control
## main script for the voice over sample using godot's localisation.
## demonstrates voice over with TranslationServer integration.

@onready var dialogue_runner: YarnDialogueRunner = $YarnDialogueRunner
@onready var language_menu: OptionButton = $UI/LanguageMenu
@onready var start_button: Button = $UI/StartButton

## available languages with their locale codes (godot format)
var languages := {
	"English": "en",
	"Deutsch": "de",
	"中文": "zh",
	"Portugues (BR)": "pt_BR"
}


func _ready() -> void:
	# Voice-over audio: point the runner at the base-language (en) files.
	# The other locales come from Godot's translation remaps, and the line
	# text comes from real .translation resources whicre both registered in
	# Project Settings > Localization.
	dialogue_runner.set_audio_base_path("res://samples/voice_over/dialogue/audio/en/")

	# populate language menu
	_setup_language_menu()

	# connect signals
	start_button.pressed.connect(_on_start_pressed)
	language_menu.item_selected.connect(_on_language_selected)
	# note: dialogue_completed signal is connected in the scene file

	# set initial locale
	TranslationServer.set_locale("en")


func _setup_language_menu() -> void:
	language_menu.clear()
	var idx := 0
	for lang_name in languages:
		language_menu.add_item(lang_name, idx)
		idx += 1


func _on_start_pressed() -> void:
	start_button.visible = false
	language_menu.visible = false
	dialogue_runner.start_dialogue("Start")


func _on_language_selected(index: int) -> void:
	var lang_name := language_menu.get_item_text(index)
	var locale: String = languages[lang_name]
	TranslationServer.set_locale(locale)
	print("Language set to: %s (%s)" % [lang_name, locale])


func _on_dialogue_completed() -> void:
	# show UI again after dialogue ends
	start_button.visible = true
	language_menu.visible = true


func _input(event: InputEvent) -> void:
	# quick language switch with number keys (for testing)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				TranslationServer.set_locale("en")
				print("Switched to English")
			KEY_2:
				TranslationServer.set_locale("de")
				print("Switched to German")
			KEY_3:
				TranslationServer.set_locale("zh")
				print("Switched to Chinese")
			KEY_4:
				TranslationServer.set_locale("pt_BR")
				print("Switched to Portuguese (BR)")
