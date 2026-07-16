class_name ChatterNPC
extends Node

## Marks a character as one that can speak background chatter, and exposes the
## world point above which their floating lines should appear. Presenters find
## a speaker by name and anchor the line to its chatter point.
##
## Attach as a child of a character (a Node3D). The speaker name used in the
## Yarn lines is matched against [member speaker_name] (defaulting to the
## parent character's node name).

## The name lines address this character by. Empty falls back to the parent's name.
@export var speaker_name: String = ""
## Local height above the character's origin to float lines at.
@export var chatter_height: float = 0.95

var _character: Node3D


func _ready() -> void:
	add_to_group(&"chatter_npc")
	_character = get_parent() as Node3D
	if speaker_name.is_empty() and _character != null:
		speaker_name = _character.name


## World position to anchor a floating line above this character.
func chatter_point() -> Vector3:
	if _character == null:
		return Vector3.ZERO
	return _character.global_position + Vector3.UP * chatter_height


## Finds an active chatter NPC by the name lines address it by.
static func find_by_name(tree: SceneTree, speaker: String) -> ChatterNPC:
	for npc in tree.get_nodes_in_group(&"chatter_npc"):
		if npc is ChatterNPC and (npc as ChatterNPC).speaker_name == speaker:
			return npc
	return null
