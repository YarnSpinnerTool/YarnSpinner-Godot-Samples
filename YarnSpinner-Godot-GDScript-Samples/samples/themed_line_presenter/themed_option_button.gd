class_name ThemedOptionButton
extends YarnOptionButton

@onready var _indicator: TextureRect = $SelectionIndicator


func _sync_indicator() -> void:
	_indicator.visible = has_focus()
