# Main game script for the instance commands example.
# Demonstrates how to register instance commands so Yarn can call
# methods directly on specific character nodes.

extends Node2D

## Reference to the dialogue runner
@onready var dialogue_runner: YarnDialogueRunner = $YarnDialogueRunner

## Reference to the line presenter
@onready var line_presenter: YarnLinePresenter = $UI/LinePresenter

## Reference to the options presenter
@onready var options_presenter: YarnOptionsPresenter = $UI/OptionsPresenter

## Start button
@onready var start_button: Button = $UI/StartButton


func _ready() -> void:
	# Add presenters to dialogue runner
	dialogue_runner.add_presenter(line_presenter)
	dialogue_runner.add_presenter(options_presenter)

	# Connect signals
	start_button.pressed.connect(_on_start_pressed)
	dialogue_runner.dialogue_completed.connect(_on_dialogue_completed)


func _on_start_pressed() -> void:
	start_button.visible = false
	dialogue_runner.start_dialogue("Start")


func _on_dialogue_completed() -> void:
	start_button.text = "Restart"
	start_button.visible = true
