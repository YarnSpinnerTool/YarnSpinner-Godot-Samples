class_name TheRoomVariableStorage
extends YarnInMemoryVariableStorage

## Typed accessors over the Yarn variables that describe the scene about to be
## played: who is in it, where it happens, and what kind of scene it is.
## The Character, Scenario and Room enums are declared in Room.yarn and stored
## as their backing strings; ScenarioState is stored as its backing integer.
## Game code (the pillars and the level god) reads and writes the world through
## here rather than poking variable names directly.

enum Character { ALICE, BARRY, GEORGE, LIZ }
enum Scenario { INTERROGATION, EXPLORE, RESCUE, DATE }
enum Room { OFFICE, PUB, CHURCH, MANSION }
enum ScenarioState { NOT_STARTED = 0, STARTED = 1, COMPLETE = 2 }

const CHARACTER_NAMES: Array[String] = ["Alice", "Barry", "George", "Liz"]
const SCENARIO_NAMES: Array[String] = ["Interrogation", "Explore", "Rescue", "Date"]
const ROOM_NAMES: Array[String] = ["Office", "Pub", "Church", "Mansion"]


## the character playing the primary role
func get_primary() -> Character:
	return _to_enum(get_string("$primary", CHARACTER_NAMES[0]), CHARACTER_NAMES) as Character


func set_primary(value: Character) -> void:
	set_value("$primary", CHARACTER_NAMES[value])


## the character playing the secondary role
func get_secondary() -> Character:
	return _to_enum(get_string("$secondary", CHARACTER_NAMES[1]), CHARACTER_NAMES) as Character


func set_secondary(value: Character) -> void:
	set_value("$secondary", CHARACTER_NAMES[value])


## the kind of scene that will play out
func get_scenario() -> Scenario:
	return _to_enum(get_string("$scenario", SCENARIO_NAMES[0]), SCENARIO_NAMES) as Scenario


func set_scenario(value: Scenario) -> void:
	set_value("$scenario", SCENARIO_NAMES[value])


## the room the scene is set inside
func get_room() -> Room:
	return _to_enum(get_string("$Room", ROOM_NAMES[0]), ROOM_NAMES) as Room


func set_room(value: Room) -> void:
	set_value("$Room", ROOM_NAMES[value])


## how far through the scenario the player is
func get_scenario_state() -> ScenarioState:
	return int(get_float("$scenario_state", 0.0)) as ScenarioState


func set_scenario_state(value: ScenarioState) -> void:
	set_value("$scenario_state", float(value))


func get_speak_to_primary() -> bool:
	return get_bool("$speak_to_primary", false)


func set_speak_to_primary(value: bool) -> void:
	set_value("$speak_to_primary", value)


func get_speak_to_secondary() -> bool:
	return get_bool("$speak_to_secondary", false)


func set_speak_to_secondary(value: bool) -> void:
	set_value("$speak_to_secondary", value)


## The name of the character currently in the primary role, as Yarn stores it.
func get_primary_name() -> String:
	return CHARACTER_NAMES[get_primary()]


## The name of the character currently in the secondary role.
func get_secondary_name() -> String:
	return CHARACTER_NAMES[get_secondary()]


func _to_enum(backing_value: String, names: Array[String]) -> int:
	var index := names.find(backing_value)
	return index if index >= 0 else 0
