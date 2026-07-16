class_name ChatterGroupManager
extends Node

## Drives all the ambient conversations in the scene.
##
## For each child [ChatterGroup] it runs an independent loop: wait a random
## delay, and if the player is in start range and the primary conversation
## isn't blocking it, run the group's chatter. While running, it watches for the
## player leaving the stop radius. When the primary conversation starts, all
## interruptible groups are stopped immediately.

@export var player: Node3D
@export var primary_dialogue_runner: YarnDialogueRunner
## Range (seconds) of the random delay between a group's conversations.
@export var min_delay: float = 0.0
@export var max_delay: float = 1.0

var _groups: Array[ChatterGroup] = []


func _ready() -> void:
	for child in _all_descendants(self):
		if child is ChatterGroup:
			_groups.append(child)

	if primary_dialogue_runner != null:
		primary_dialogue_runner.dialogue_started.connect(_interrupt_all_chatter)

	for group in _groups:
		_run_group_loop(group)


func _exit_tree() -> void:
	if primary_dialogue_runner != null and primary_dialogue_runner.dialogue_started.is_connected(_interrupt_all_chatter):
		primary_dialogue_runner.dialogue_started.disconnect(_interrupt_all_chatter)


## A perpetual loop for one chatter group.
func _run_group_loop(group: ChatterGroup) -> void:
	while is_inside_tree() and is_instance_valid(group):
		if group.start_immediately_on_enter:
			await get_tree().process_frame
		else:
			await get_tree().create_timer(randf_range(min_delay, max_delay)).timeout

		if not is_inside_tree() or not is_instance_valid(group):
			return

		# Primary conversation is running and this group yields to it; skip.
		if _primary_blocks(group):
			continue
		if group.is_running():
			continue
		if player != null and not group.in_start_range(player.global_position):
			continue

		await _run_until_done(group)

		# When triggered on enter, wait for the player to leave before allowing
		# the conversation to fire again, so it doesn't loop instantly.
		if group.start_immediately_on_enter and player != null:
			while is_inside_tree() and group.in_start_range(player.global_position):
				await get_tree().process_frame


## Runs the chatter and watches for the player leaving the stop radius until the
## conversation completes.
func _run_until_done(group: ChatterGroup) -> void:
	# Single-element array used as a reference-type completion flag, so the
	# detached run coroutine can signal the polling loop below.
	var done := [false]
	_run_chatter_then(group, done)

	var notified_left := false
	while not done[0] and is_inside_tree() and is_instance_valid(group):
		if player != null and not notified_left and group.outside_stop_range(player.global_position):
			notified_left = true
			await group.on_left_stop_range()
		await get_tree().process_frame


func _run_chatter_then(group: ChatterGroup, done: Array) -> void:
	await group.run_chatter()
	done[0] = true


func _primary_blocks(group: ChatterGroup) -> bool:
	return primary_dialogue_runner != null \
		and primary_dialogue_runner.is_running() \
		and group.interrupted_by_primary


## Stops every interruptible chatter when the player starts a real conversation.
func _interrupt_all_chatter() -> void:
	for group in _groups:
		if group.interrupted_by_primary:
			group.interrupt()


func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result
