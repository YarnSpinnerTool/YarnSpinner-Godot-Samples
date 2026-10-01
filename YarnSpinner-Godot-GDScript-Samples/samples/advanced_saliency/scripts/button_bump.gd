class_name ButtonBump
extends Area3D

## The pillar's value; found on the parent if left unset.
@export var updater: ValueUpdater


func _ready() -> void:
	if updater == null:
		updater = _find_updater(get_parent())


func _on_body_entered(body: Node3D) -> void:
	if updater != null and body is SimpleCharacter:
		updater.update_value()


func _find_updater(node: Node) -> ValueUpdater:
	if node == null:
		return null
	if node is ValueUpdater:
		return node
	for child in node.get_children():
		if child is ValueUpdater:
			return child
	return null
