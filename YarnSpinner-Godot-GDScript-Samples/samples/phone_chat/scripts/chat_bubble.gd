# This Source Code is subject to the terms of the LICENSE.md file
# located in the root of this project.

class_name ChatBubble
extends Control
## a single chat message bubble. Can show a typing indicator instead of
## text while the "sender" is typing. Amazing.

## the the label the message is shown in
@export var label: Label
## optional; bubbles without one never show a typing state
@export var typing_indicator: Control
## widest the text may grow before wrapping onto more lines. The bubble kinda
## hugs shorter messages (the Godot stand-in for Unity's UseSizeOfText, I think).
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


## With autowrap on, a Label's minimum width is one character, so
## containers collapse it to a vertical strip which sucks. Size it to ,
## its text insteadcapped at max_text_width so long messages wrap.
func _fit_label() -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var measured := font.get_string_size(label.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	label.custom_minimum_size.x = minf(measured + 2.0, max_text_width)
