extends AnimationTree

@export var mean_blink_time: float = 2
@export var blink_variance: float = 0.5

var time_until_next_blink: float

func _ready() -> void:
	blink()
	pass

func get_next_blink_time() -> float:
	return mean_blink_time + lerp(-blink_variance, blink_variance, randf())

func blink():
	while true:
		await get_tree().create_timer(get_next_blink_time()).timeout
		self.set("parameters/Blink/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
