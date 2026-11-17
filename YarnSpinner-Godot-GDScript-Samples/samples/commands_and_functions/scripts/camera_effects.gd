extends Camera2D


func shake(intensity: float) -> void:
	var strength := intensity * 20.0
	var tween := create_tween()
	tween.tween_property(self, "offset", Vector2(strength, 0), 0.05)
	tween.tween_property(self, "offset", Vector2(-strength, 0), 0.05)
	tween.tween_property(self, "offset", Vector2(strength * 0.5, 0), 0.05)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.1)


func shake_and_wait(intensity: float, duration: float = 0.5) -> void:
	var strength := intensity * 20.0
	var time := duration

	var tween := create_tween()
	var shake_count := int(time / 0.1)

	for i in range(shake_count):
		var decay := 1.0 - (float(i) / shake_count)
		tween.tween_property(self, "offset", Vector2(strength * decay, 0), 0.025)
		tween.tween_property(self, "offset", Vector2(-strength * decay, 0), 0.025)
		tween.tween_property(self, "offset", Vector2(0, strength * decay * 0.5), 0.025)
		tween.tween_property(self, "offset", Vector2(0, -strength * decay * 0.5), 0.025)

	tween.tween_property(self, "offset", Vector2.ZERO, 0.05)

	await tween.finished


func zoom_to(target_zoom: float, duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(self, "zoom", Vector2(target_zoom, target_zoom), duration)

	await tween.finished


func reset() -> void:
	offset = Vector2.ZERO
	zoom = Vector2.ONE
