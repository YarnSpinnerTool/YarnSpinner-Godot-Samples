extends Node2D

@onready var dialogue_runner: YarnDialogueRunner = $YarnDialogueRunner

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
