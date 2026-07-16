class_name BasicSaliencyVariableStorage
extends YarnInMemoryVariableStorage

## Typed accessors over the Yarn variables used by the Basic Saliency sample.
## The Yarn enums are stored as their backing integers, and these helpers give
## game code (the TimeAdvancer) a friendly, type-safe way to read and change
## the current day and time.

enum Day { MONDAY = 0, TUESDAY = 1, WEDNESDAY = 2 }
enum TimeOfDay { MORNING = 0, EVENING = 1 }


## the current day
func get_day() -> Day:
	return int(get_float("$day", 0.0)) as Day


func set_day(value: Day) -> void:
	set_value("$day", float(value))


## the current time of day
func get_time() -> TimeOfDay:
	return int(get_float("$time", 0.0)) as TimeOfDay


func set_time(value: TimeOfDay) -> void:
	set_value("$time", float(value))


## the number of gold coins the player has
func get_gold() -> float:
	return get_float("$gold", 0.0)


func set_gold(value: float) -> void:
	set_value("$gold", value)
