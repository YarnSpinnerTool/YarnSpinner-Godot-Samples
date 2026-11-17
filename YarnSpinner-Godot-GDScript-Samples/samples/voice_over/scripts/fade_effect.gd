class_name FadeEffect
extends ColorRect

@export var default_duration: float = 1.0

@export var dialogue_runner: YarnDialogueRunner

static var _instance: FadeEffect


func _ready() -> void:
	_instance = self

	color = Color(0, 0, 0, 0)

	if dialogue_runner != null:
		_register_commands()


func _register_commands() -> void:
	dialogue_runner.add_command("set_fade_color", _cmd_set_fade_color)
	dialogue_runner.add_command("fade_up", _cmd_fade_up)
	dialogue_runner.add_command("fade_down", _cmd_fade_down)


func _cmd_set_fade_color(opacity: float) -> void:
	color = Color(0, 0, 0, opacity)


func _cmd_fade_up(duration: float = 1.0, wait: bool = false) -> void:
	var finished := _fade(1.0, 0.0, duration)
	if wait:
		await finished


func _cmd_fade_down(duration: float = 1.0, wait: bool = false) -> void:
	var finished := _fade(0.0, 1.0, duration)
	if wait:
		await finished


func _fade(from: float, to: float, duration: float) -> Signal:
	var tween := create_tween()
	color.a = from
	tween.tween_property(self, "color:a", to, duration)
	return tween.finished


static func get_instance() -> FadeEffect:
	return _instance


static func fade_up_static(duration: float = 1.0) -> Signal:
	if _instance != null:
		return _instance._fade(_instance.color.a, 0.0, duration)
	return Signal()


static func fade_down_static(duration: float = 1.0) -> Signal:
	if _instance != null:
		return _instance._fade(_instance.color.a, 1.0, duration)
	return Signal()
