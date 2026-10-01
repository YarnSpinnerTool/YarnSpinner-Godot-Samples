class_name ValueUpdater
extends Node

## One button pillar thingy's worth of state: shows which value it controls and steps that
## value to the next case each time the player bumps into it. A big fancy button, basically.

enum ValueObserved { PRIMARY, SECONDARY, ROOM, SCENARIO }

@export var observation: ValueObserved = ValueObserved.PRIMARY
@export var label: Label3D
@export var storage: TheRoomVariableStorage


func _ready() -> void:
	# Deferred because the dialogue runner loads the Yarn program (and with it the
	# variables' initial values) in its own _ready, which runs after ours.
	update_labels.call_deferred()


## Steps this pillar's value to the next case and refreshes the label...
func update_value() -> void:
	match observation:
		ValueObserved.PRIMARY:
			storage.set_primary(_next(storage.get_primary(), TheRoomVariableStorage.Character.size()))
		ValueObserved.SECONDARY:
			storage.set_secondary(_next(storage.get_secondary(), TheRoomVariableStorage.Character.size()))
		ValueObserved.ROOM:
			storage.set_room(_next(storage.get_room(), TheRoomVariableStorage.Room.size()))
		ValueObserved.SCENARIO:
			storage.set_scenario(_next(storage.get_scenario(), TheRoomVariableStorage.Scenario.size()))
	update_labels()


func update_labels() -> void:
	if label == null or storage == null:
		return
	match observation:
		ValueObserved.PRIMARY:
			label.text = "The Primary role is played by %s" % storage.get_primary_name()
		ValueObserved.SECONDARY:
			label.text = "The Secondary role is played by %s" % storage.get_secondary_name()
		ValueObserved.SCENARIO:
			label.text = "It will be %s scene" % _with_article(_case_name(TheRoomVariableStorage.Scenario.keys()[storage.get_scenario()]))
		ValueObserved.ROOM:
			label.text = "It is set inside %s" % _with_article(_case_name(TheRoomVariableStorage.Room.keys()[storage.get_room()]))


func _next(current: int, count: int) -> int:
	return (current + 1) % count


func _with_article(word: String) -> String:
	var article := "an" if word.left(1).to_lower() in ["a", "e", "i", "o", "u"] else "a"
	return "%s %s" % [article, word]


## Godot Enum keys are typically SHOUTING_CASE; the labels use the Yarn case names. 
## LESS SHOUTING 
## EVEN THOUGH SHOUTING IS FUN
func _case_name(key: String) -> String:
	return key.capitalize()
