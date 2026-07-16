class_name ThemedOptionButton
extends Button
## Option row for the Themed Line Presenter sample: plain text with the
## atlas triangle (the Option-Selected sprite) marking the focused option.

@onready var _indicator: TextureRect = $SelectionIndicator


func _ready() -> void:
	_sync_indicator()
	focus_entered.connect(_sync_indicator)
	focus_exited.connect(_sync_indicator)
	tree_entered.connect(_sync_indicator)


func _sync_indicator() -> void:
	_indicator.visible = has_focus()
