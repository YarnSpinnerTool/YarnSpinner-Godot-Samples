extends Node3D

@onready var dialogue_runner: YarnDialogueRunner = $YarnDialogueRunner

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# set audio path template for godot localisation
	dialogue_runner.set_audio_path_template("res://samples/voice_over_3d/dialogue/audio/{locale}/")

	pass
