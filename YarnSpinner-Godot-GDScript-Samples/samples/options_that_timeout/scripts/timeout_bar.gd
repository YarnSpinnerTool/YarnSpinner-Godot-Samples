class_name TimeoutBar
extends Control


signal finished

@export var bar: Control

var _original_width: float = 0.0
var _running := false


func _ready() -> void:
	if bar != null:
		_original_width = maxf(bar.size.x, bar.custom_minimum_size.x)


func shrink(duration: float) -> void:
	if bar == null:
		return
	reset()
	_running = true
	var start_width := bar.size.x
	var elapsed := 0.0
	var tree := get_tree()
	while _running and elapsed < duration:
		await tree.process_frame
		elapsed += get_process_delta_time()
		var t := clampf(elapsed / duration, 0.0, 1.0)
		_set_width(lerpf(start_width, 0.0, t))
	if not _running:
		return
	_set_width(0.0)
	_running = false
	finished.emit()


func cancel() -> void:
	_running = false


func reset() -> void:
	_running = false
	if bar != null:
		_set_width(_original_width)


func _set_width(w: float) -> void:
	bar.offset_left = -w * 0.5
	bar.offset_right = w * 0.5
