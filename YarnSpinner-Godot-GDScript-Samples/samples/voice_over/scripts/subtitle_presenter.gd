# This Source Code Form is subject to the terms of the LICENSE.md file
# located in the root of this project.

class_name SubtitlePresenter
extends YarnDialoguePresenter
## Shows the line text as a bare subtitle over the scene.
##
## This presenter holds the line until another presenter ends it, so pair
## it with something that does — like YarnVoiceOverPresenter with
## end_line_when_voice_complete on, or the player skipping.

## the label the subtitle text is shown in
@export var label: Label


func _ready() -> void:
	if label != null:
		label.visible = false


func run_line(line: YarnLine, token: YarnCancellationToken = null) -> void:
	if label == null:
		return

	label.text = line.text_without_character_name
	label.visible = true

	# wait until the line has been ended by someone else
	if token != null:
		await token.wait_for_next_content()

	label.visible = false
