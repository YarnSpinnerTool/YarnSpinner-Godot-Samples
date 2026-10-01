# This Source Code is subject to the terms of the LICENSE.md file
# located in the root of this project.

extends ColorRect
## Sample screen effects node demonstrating async visual commands.
##
## Shows fade effects that pause dialogue until complete.


## Fades the screen to black (async - dialogue waits).
## Bound as: <<fade_out 0.5>>
func fade_out(duration: String = "0.5") -> Signal:
	var time := float(duration)
	color = Color(0, 0, 0, color.a)
	var tween := create_tween()
	tween.tween_property(self, "color:a", 1.0, time)
	return tween.finished


## Fades the screen from black (async - dialogue waits).
## Bound as: <<fade_in 0.5>>
func fade_in(duration: String = "0.5") -> Signal:
	var time := float(duration)
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.0, time)
	return tween.finished


## Flashes the screen a color briefly.
## Bound as: <<flash red 0.2>> or <<flash white 0.1>>
func flash(color_name: String, duration: String = "0.2") -> Signal:
	var flash_color := _parse_color(color_name)
	flash_color.a = 0.8
	var time := float(duration)

	color = flash_color
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.0, time)
	return tween.finished


func _parse_color(color_name: String) -> Color:
	match color_name.to_lower():
		"white": return Color.WHITE
		"black": return Color.BLACK
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		_: return Color.BLACK
