extends Area3D

## The floor button that advances the day/time when the player walks into it,
## and keeps the world-space label in sync.

const Day := BasicSaliencyVariableStorage.Day
const TimeOfDay := BasicSaliencyVariableStorage.TimeOfDay

@export var variable_store: BasicSaliencyVariableStorage
@export var label: Label3D

const _DAY_NAMES := {
	Day.MONDAY: "Monday",
	Day.TUESDAY: "Tuesday",
	Day.WEDNESDAY: "Wednesday",
}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_label()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		_advance_time()
		_update_label()


func _advance_time() -> void:
	if variable_store == null:
		push_warning("TimeAdvancer: variable_store is not set")
		return

	# Morning steps to evening; evening wraps to the next day's morning,
	# with Wednesday looping back to Monday.
	if variable_store.get_time() == TimeOfDay.MORNING:
		variable_store.set_time(TimeOfDay.EVENING)
		return

	variable_store.set_time(TimeOfDay.MORNING)
	match variable_store.get_day():
		Day.MONDAY:
			variable_store.set_day(Day.TUESDAY)
		Day.TUESDAY:
			variable_store.set_day(Day.WEDNESDAY)
		Day.WEDNESDAY:
			variable_store.set_day(Day.MONDAY)


func _update_label() -> void:
	if label == null or variable_store == null:
		return
	var day: String = _DAY_NAMES.get(variable_store.get_day(), "Monday")
	var time := "morning" if variable_store.get_time() == TimeOfDay.MORNING else "evening"
	label.text = "It is %s %s." % [day, time]
