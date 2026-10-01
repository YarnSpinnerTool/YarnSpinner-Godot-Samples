# This Source Code is subject to the terms of the LICENSE.md file
# located in the root of this project.

extends Node2D
## Main controller for the Bindings Sample.
##
## This sample demonstrates the YarnBindingLoader system which allows
## visual configuration of Yarn commands and functions in the inspector.
##
## === HOW TO USE THE INSPECTOR (Recommended) ===
##
## 1. Select the YarnBindingLoader node in the Scene tree
## 2. In the Inspector, find the "Bindings" array property
## 3. Click "Add Element" to add a new binding
## 4. Configure each binding:
##
##    Example Command Binding:
##      Yarn Name: shake
##      Type: COMMAND
##      Target Node: ../Camera2D
##      Method Name: shake
##      Description: Shakes the camera
##
##    Example Function Binding:
##      Yarn Name: player_health
##      Type: FUNCTION
##      Target Node: ../Player
##      Method Name: get_health
##      Parameter Count: 0
##      Description: Returns player's current health


@onready var dialogue_runner: YarnDialogueRunner = $YarnDialogueRunner
@onready var binding_loader: YarnBindingLoader = $YarnBindingLoader
@onready var player: Node = $Player
@onready var camera: Camera2D = $Camera2D
@onready var status_label: Label = $UILayer/UI/StatusPanel/StatusLabel
@onready var start_button: Button = $UILayer/UI/StartButton
@onready var restart_button: Button = $UILayer/UI/RestartButton


func _ready() -> void:
	_update_status()


func _on_start_pressed() -> void:
	start_button.visible = false
	dialogue_runner.start_dialogue("Start")


func _on_restart_pressed() -> void:
	# Reset all game state, including the Yarn variables, otherwise the
	# dialogue keeps the old $gold while the Player node starts
	# fresh, and the two disagree.
	player.reset()
	camera.reset()
	dialogue_runner.variable_storage.clear()

	restart_button.visible = false
	start_button.visible = true
	_update_status()


func _on_dialogue_completed() -> void:
	restart_button.visible = true
	_update_status()


func _on_bindings_registered() -> void:
	print("=== Bindings Sample ===")
	print(binding_loader.get_debug_info())


func _on_binding_failed(binding: YarnCommandBinding, reason: String) -> void:
	push_error("Binding failed: %s - %s" % [binding.yarn_name, reason])


func _process(_delta: float) -> void:
	if dialogue_runner.is_running():
		_update_status()


func _update_status() -> void:
	# Read gold from Yarn variables (which the dialogue updates via <<set>>)
	var yarn_gold: int = 50
	var storage := dialogue_runner.variable_storage
	if storage:
		yarn_gold = int(storage.get_value("$gold"))

	var lines := PackedStringArray()
	lines.append("Health: %d/100" % player.health)
	lines.append("Gold: %d" % yarn_gold)
	lines.append("Inventory: %s" % (", ".join(player.inventory) if player.inventory.size() > 0 else "(empty)"))
	status_label.text = "\n".join(lines)
