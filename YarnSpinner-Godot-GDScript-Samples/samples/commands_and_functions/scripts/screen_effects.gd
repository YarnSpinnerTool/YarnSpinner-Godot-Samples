extends ColorRect


func fade_out(duration: float = 0.5) -> void:
	color = Color(0, 0, 0, color.a)
	var tween := create_tween()
	tween.tween_property(self, "color:a", 1.0, duration)
	await tween.finished


func fade_in(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.0, duration)
	await tween.finished


func flash(color_name: String, duration: float = 0.2) -> void:
	var flash_color := _parse_color(color_name)
	flash_color.a = 0.8

	color = flash_color
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.0, duration)
	await tween.finished


func _parse_color(color_name: String) -> Color:
	match color_name.to_lower():
		"white": return Color.WHITE
		"black": return Color.BLACK
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		_: return Color.BLACK
