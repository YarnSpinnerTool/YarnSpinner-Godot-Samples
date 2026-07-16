class_name TimeoutBar
extends Control

## A countdown bar that shrinks a child rect's width to zero over a duration.
## Emits [signal finished] when the bar empties, unless it is cancelled
## first.

signal finished

## the rect whose width is animated; defaults to the first Control child
@export var bar: Control

var _original_width: float = 0.0
var _running := false


func _ready() -> void:
	if bar == null:
		for child in get_children():
			if child is Control:
				bar = child
				break
	if bar != null:
		# Prefer the authored minimum width; size.x may be 0 before first layout.
		_original_width = maxf(bar.size.x, bar.custom_minimum_size.x)


## Animates the bar to empty over [param duration] seconds, awaiting completion.
## Call [method cancel] to stop early without emitting [signal finished].
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


## Stops an in-progress shrink without emitting [signal finished].
func cancel() -> void:
	_running = false


## Restores the bar to its full width.
func reset() -> void:
	_running = false
	if bar != null:
		_set_width(_original_width)


func _set_width(w: float) -> void:
	bar.custom_minimum_size.x = w
	bar.size.x = w
