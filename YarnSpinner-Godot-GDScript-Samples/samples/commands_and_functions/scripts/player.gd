extends Node


var health: int = 100

var inventory: Array[String] = []


func get_health() -> int:
	return health


func has_item(item_name: String) -> bool:
	return item_name in inventory


func add_item(item_name: String) -> void:
	inventory.append(item_name)
	print("Player received: %s" % item_name)


func modify_health(amount: int) -> void:
	health += amount
	health = clampi(health, 0, 100)
	print("Player health: %d" % health)


func reset() -> void:
	health = 100
	inventory.clear()
