extends Button

signal item_picked(food: int)

@export var food: CustomFunctionsVariables.FoodType
@export var selectable := false
@export var hover: ColorRect
@export var count_badge: Control
@export var count_label: Label
@export var normal_colour := Color(1, 1, 1, 0)
@export var hover_colour := Color(1, 1, 1, 1)
@export var click_colour := Color(1, 0, 0, 1)


func _ready() -> void:
	hover.color = normal_colour
	pressed.connect(func() -> void: item_picked.emit(food))
	mouse_entered.connect(_set_hover.bind(hover_colour))
	focus_entered.connect(_set_hover.bind(hover_colour))
	mouse_exited.connect(_set_hover.bind(normal_colour))
	focus_exited.connect(_set_hover.bind(normal_colour))
	button_down.connect(_set_hover.bind(click_colour))
	button_up.connect(_set_hover.bind(normal_colour))


func set_count(count: int) -> void:
	visible = count > 0
	count_badge.visible = count >= 2
	count_label.text = str(count)


func _set_hover(colour: Color) -> void:
	if selectable:
		hover.color = colour
