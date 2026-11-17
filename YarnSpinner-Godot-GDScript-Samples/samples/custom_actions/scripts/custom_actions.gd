extends Node3D

@export var dialogue_runner: YarnDialogueRunner
@export var display_panel: Control
@export var selection_panel: Control
@export var eat_sound: AudioStreamPlayer
@export var inventory_layer: CanvasLayer

var _inventory: Dictionary[int, int] = {}
var _is_selecting := false


func _ready() -> void:
	dialogue_runner.add_command("add_inventory_item", _add_inventory_item)
	dialogue_runner.add_command("remove_inventory_item", _remove_inventory_item)
	dialogue_runner.add_command("walk_to_point_eat_and_return", _walk_to_point_eat_and_return)
	dialogue_runner.add_function("has_inventory_item", _has_inventory_item)
	dialogue_runner.add_function("has_any_inventory_items", _has_any_inventory_items)
	dialogue_runner.add_function("inventory_count", _inventory_count)
	dialogue_runner.add_function("pick_inventory_item", _pick_inventory_item)
	_update_inventory_panels()
	get_viewport().size_changed.connect(_scale_inventory)
	_scale_inventory()


func _scale_inventory() -> void:
	var size := get_viewport().get_visible_rect().size
	var factor := size.y / 1080.0
	inventory_layer.scale = Vector2(factor, factor)
	inventory_layer.offset = Vector2((size.x - 1920.0 * factor) / 2.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue_runner.is_running():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		dialogue_runner.stop_dialogue()
	elif event.is_action_pressed("ui_accept") and not dialogue_runner.is_presenting_line() and not _is_selecting:
		get_viewport().set_input_as_handled()
		dialogue_runner.request_next_content()


func _update_inventory_panels() -> void:
	var entries: PackedStringArray = []
	for food in _inventory:
		entries.append("%s: %d" % [String(CustomFunctionsVariables.FoodType.find_key(food)).capitalize(), _inventory[food]])
	print("Inventory: " + ", ".join(entries))
	display_panel.visible = display_panel.update_display(_inventory) and not _is_selecting
	selection_panel.visible = selection_panel.update_display(_inventory) and _is_selecting


func _add_inventory_item(food: CustomFunctionsVariables.FoodType, count: int = 1) -> void:
	_inventory[food] = maxi(_inventory.get(food, 0) + count, 0)
	_update_inventory_panels()


func _remove_inventory_item(food: CustomFunctionsVariables.FoodType, count: int = 1) -> void:
	_inventory[food] = maxi(_inventory.get(food, 0) - count, 0)
	_update_inventory_panels()


func _has_inventory_item(food: CustomFunctionsVariables.FoodType) -> bool:
	return _inventory.get(food, 0) > 0


func _has_any_inventory_items() -> bool:
	for count in _inventory.values():
		if count > 0:
			return true
	return false


func _inventory_count(food: CustomFunctionsVariables.FoodType) -> int:
	return _inventory.get(food, 0)


func _pick_inventory_item(token: YarnCancellationToken) -> String:
	var none := CustomFunctionsVariables.FoodType.NONE
	if token.is_next_content_requested or not _has_any_inventory_items():
		return CustomFunctionsVariables._FOOD_TYPE_VALUES[none]

	var picked := YarnPromise.new()
	var on_picked := func(food: int) -> void: picked.settle(food)
	var on_cancelled := func() -> void: picked.settle(none)
	selection_panel.item_picked.connect(on_picked)
	token.next_content_requested.connect(on_cancelled)

	_is_selecting = true
	_update_inventory_panels()
	selection_panel.focus_first_item()

	var result: int = await picked.wait()

	_is_selecting = false
	_update_inventory_panels()
	selection_panel.item_picked.disconnect(on_picked)
	token.next_content_requested.disconnect(on_cancelled)
	return CustomFunctionsVariables._FOOD_TYPE_VALUES[result]


func _walk_to_point_eat_and_return(character: SimpleCharacter, destination: Node3D, token: YarnCancellationToken) -> void:
	if character == null:
		push_warning("Target doesn't have a SimpleCharacter")
		return
	if destination == null:
		return
	var start_position := character.global_position
	var start_facing := character.global_basis.z

	await character.move_to(destination.global_position, token)

	eat_sound.play()
	await token.wait_for_cancellation(1.0)

	await character.move_to(start_position, token)
	character.set_look_direction(start_facing)
	eat_sound.stop()
