class_name CharacterColorPresenter
extends YarnDialoguePresenter

@export var character_colors: Dictionary[String, Color] = {
	"Tom": Color(0.9962189, 1.0, 0.3726415),
	"Anne": Color(0.291, 0.90546674, 1.0),
}

@export var default_color: Color = Color.WHITE

@export var text_labels: Array[Control] = []


func on_dialogue_started() -> void:
	pass


func on_dialogue_completed() -> void:
	pass


func run_line(line: YarnLine, _token: YarnCancellationToken = null) -> void:
	var color := default_color

	if not line.character_name.is_empty():
		if character_colors.has(line.character_name):
			color = character_colors[line.character_name]

	for label in text_labels:
		if label != null and is_instance_valid(label):
			if label is Label:
				(label as Label).modulate = color
			elif label is RichTextLabel:
				(label as RichTextLabel).modulate = color


func run_options(_options: Array[YarnOption], _token: YarnCancellationToken = null) -> int:
	return -1
