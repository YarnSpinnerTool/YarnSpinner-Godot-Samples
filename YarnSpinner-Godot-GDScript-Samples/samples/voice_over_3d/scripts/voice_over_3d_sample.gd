extends Node3D

@onready var dialogue_runner: YarnDialogueRunner = $YarnDialogueRunner


func _ready() -> void:
	dialogue_runner.set_audio_base_path("res://samples/voice_over_3d/dialogue/audio/en/")
