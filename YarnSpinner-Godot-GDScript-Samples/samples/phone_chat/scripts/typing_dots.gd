# This Source Code is subject to the terms of the LICENSE.md file
# located in the root of this project.

extends HBoxContainer
## pulses the three dots of a typing indicator, one after another.


func _ready() -> void:
	var tween := create_tween().set_loops()
	for dot in get_children():
		tween.tween_property(dot, "modulate:a", 1.0, 0.2).from(0.3)
		tween.tween_property(dot, "modulate:a", 0.3, 0.2)
