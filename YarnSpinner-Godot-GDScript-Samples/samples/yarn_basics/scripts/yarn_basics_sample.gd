extends Node2D


@export var dialogue_runner: YarnDialogueRunner
@export var ui_layer: CanvasLayer
@export var background: ColorRect
@export var start_button: Button
@export var restart_button: Button


func _on_start_pressed() -> void:
	start_button.visible = false
	dialogue_runner.start_dialogue("Start")


func _on_restart_pressed() -> void:
	restart_button.visible = false
	dialogue_runner.variable_storage.clear()
	dialogue_runner.start_dialogue("Start")


func _on_dialogue_complete() -> void:
	restart_button.visible = true


func shake_camera(intensity: float = 1.0) -> void:
	var original_color := background.color

	background.color = Color.WHITE

	var tween := create_tween()
	tween.tween_property(ui_layer, "offset", Vector2(50, 0) * intensity, 0.03)
	tween.tween_property(ui_layer, "offset", Vector2(-50, 20) * intensity, 0.03)
	tween.tween_property(ui_layer, "offset", Vector2(40, -20) * intensity, 0.03)
	tween.tween_property(ui_layer, "offset", Vector2(-30, 15) * intensity, 0.03)
	tween.tween_property(ui_layer, "offset", Vector2(20, -10) * intensity, 0.03)
	tween.tween_property(ui_layer, "offset", Vector2(-10, 5) * intensity, 0.03)
	tween.tween_property(ui_layer, "offset", Vector2.ZERO, 0.05)

	var flash_tween := create_tween()
	flash_tween.tween_property(background, "color", original_color, 0.3)
