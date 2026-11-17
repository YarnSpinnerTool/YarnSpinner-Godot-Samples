extends Control

signal item_picked(food: int)

@export var slots: Array[Button] = []


func _ready() -> void:
	for slot in slots:
		slot.item_picked.connect(_on_slot_picked)


func update_display(inventory: Dictionary) -> bool:
	var any_visible := false
	for slot in slots:
		var count := int(inventory.get(slot.food, 0))
		slot.set_count(count)
		any_visible = any_visible or count > 0
	return any_visible


func focus_first_item() -> void:
	for slot in slots:
		if slot.visible:
			slot.grab_focus()
			return


func _on_slot_picked(food: int) -> void:
	print("Inventory item clicked: " + String(CustomFunctionsVariables.FoodType.find_key(food)).capitalize())
	item_picked.emit(food)
