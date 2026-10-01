# Main game script for the instance commands example.
# The dialogue runner finds the instance commands in character.gd by itself,
# so Yarn can call methods directly on specific character nodes.

extends Node2D

## Reference to the dialogue runner
@onready var dialogue_runner: YarnDialogueRunner = $YarnDialogueRunner

## Start button
@onready var start_button: Button = $UI/StartButton

@export var characters: Array[Node2D] = []


func _on_start_pressed() -> void:
	start_button.visible = false
	for character in characters:
		character.reset()
	dialogue_runner.start_dialogue("Start")


func _on_dialogue_completed() -> void:
	start_button.text = "Restart"
	start_button.visible = true
