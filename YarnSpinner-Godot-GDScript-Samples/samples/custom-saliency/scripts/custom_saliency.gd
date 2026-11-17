extends Node3D


@export var dialogue_runner: YarnDialogueRunner


func _ready() -> void:
	if dialogue_runner == null:
		push_error("custom saliency: no dialogue runner assigned")
		return

	dialogue_runner.set_content_saliency_strategy(WeightedSaliencyStrategy.new())
