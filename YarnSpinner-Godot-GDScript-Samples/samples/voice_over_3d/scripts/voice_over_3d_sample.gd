# This Source Code Form is subject to the terms of the LICENSE.md file
# located in the root of this project.

extends Node3D
## main script for the voice over 3d sample.
## points voice-over lookup at this sample's base-language audio folder;
## other locales come from Godot's translation remaps (Project Settings >
## Localization > Remaps).

@onready var dialogue_runner: YarnDialogueRunner = $YarnDialogueRunner


func _ready() -> void:
	dialogue_runner.set_audio_base_path("res://samples/voice_over_3d/dialogue/audio/en/")
