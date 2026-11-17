class_name ChatBubble
extends Control

@export var label: Label
@export var typing_indicator: Control
@export var max_text_width: float = 260.0


func has_indicator() -> bool:
	return typing_indicator != null


func show_typing() -> void:
	if typing_indicator != null:
		typing_indicator.visible = true
	if label != null:
		label.text = ""
		label.visible = false


func show_text(text: String) -> void:
	if typing_indicator != null:
		typing_indicator.visible = false
	if label != null:
		label.visible = true
		label.text = text
		_fit_label()


func _fit_label() -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var measured := font.get_string_size(label.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	label.custom_minimum_size.x = minf(measured + 2.0, max_text_width)
