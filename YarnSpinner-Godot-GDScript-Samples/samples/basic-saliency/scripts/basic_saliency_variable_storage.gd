class_name BasicSaliencyVariableStorage
extends YarnInMemoryVariableStorage


enum Day { MONDAY = 0, TUESDAY = 1, WEDNESDAY = 2 }
enum TimeOfDay { MORNING = 0, EVENING = 1 }


func get_day() -> Day:
	return int(get_float("$day", 0.0)) as Day


func set_day(value: Day) -> void:
	set_value("$day", float(value))


func get_time() -> TimeOfDay:
	return int(get_float("$time", 0.0)) as TimeOfDay


func set_time(value: TimeOfDay) -> void:
	set_value("$time", float(value))


func get_gold() -> float:
	return get_float("$gold", 0.0)


func set_gold(value: float) -> void:
	set_value("$gold", value)
