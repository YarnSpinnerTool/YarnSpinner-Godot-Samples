extends Node3D


const _DOORWAY_TILES: Array[String] = [
	"ScenarioRoom/Floor/wall-low22",
	"SetupRoom/Floor/wall-low15",
]


func _ready() -> void:
	for path in _DOORWAY_TILES:
		var tile := get_node_or_null(NodePath(path))
		if tile != null:
			tile.queue_free()
		else:
			push_warning("advanced saliency: doorway tile '%s' not found" % path)
