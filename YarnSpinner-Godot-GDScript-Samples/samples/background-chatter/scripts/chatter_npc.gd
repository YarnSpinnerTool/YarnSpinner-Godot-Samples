class_name ChatterNPC
extends Node


@export var speaker_name: String = ""
@export var chatter_height: float = 0.95

var _character: Node3D


func _ready() -> void:
	add_to_group(&"chatter_npc")
	_character = get_parent() as Node3D
	if speaker_name.is_empty() and _character != null:
		speaker_name = _character.name


func chatter_point() -> Vector3:
	if _character == null:
		return Vector3.ZERO
	return _character.global_position + Vector3.UP * chatter_height


static func find_by_name(tree: SceneTree, speaker: String) -> ChatterNPC:
	for npc in tree.get_nodes_in_group(&"chatter_npc"):
		if npc is ChatterNPC and (npc as ChatterNPC).speaker_name == speaker:
			return npc
	return null
