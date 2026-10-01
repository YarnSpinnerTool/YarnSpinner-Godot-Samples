extends Node3D

## Installs the sample's custom weighted-random saliency strategy on the dialogue
## runner.

@export var dialogue_runner: YarnDialogueRunner


func _ready() -> void:
	if dialogue_runner == null:
		push_error("custom saliency: no dialogue runner assigned")
		return

	# Install the custom weighted strategy for the runner's Custom saliency
	# setting.
	dialogue_runner.set_content_saliency_strategy(WeightedSaliencyStrategy.new())
