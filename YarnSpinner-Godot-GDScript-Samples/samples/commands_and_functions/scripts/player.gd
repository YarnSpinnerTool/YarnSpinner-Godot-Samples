# This Source Code is subject to the terms of the LICENSE.md file
# located in the root of this project.

extends Node
## Sample player node demonstrating methods that can be bound to Yarn functions.
##
## This shows how to create methods that work with YarnBindingLoader
## for both commands (actions) and functions (queries).


## Player's current health.
var health: int = 100

## Items in the player's inventory.
var inventory: Array[String] = []


# === Functions (queries that return values) ===

## Returns the player's current health.
## Bound as: {player_health()} or <<if player_health() < 50>>
func get_health() -> int:
	return health


## Checks if the player has a specific item.
## Bound as: {has_item("key")} or <<if has_item("sword")>>
func has_item(item_name: String) -> bool:
	return item_name in inventory


# === Commands (actions that do something) ===

## Adds an item to the player's inventory.
## Bound as: <<give_item "sword">>
func add_item(item_name: String) -> void:
	inventory.append(item_name)
	print("Player received: %s" % item_name)


## Heals or damages the player.
## Bound as: <<heal 25>> or <<heal -10>> for damage
func modify_health(amount: String) -> void:
	health += int(amount)
	health = clampi(health, 0, 100)
	print("Player health: %d" % health)


## Resets the player to starting state.
func reset() -> void:
	health = 100
	inventory.clear()
