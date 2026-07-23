@tool
class_name ChatterGroup
extends Node3D

## A single ambient conversation: owns a [YarnDialogueRunner] (with its own
## [BackgroundChatterView] presenter) that plays near the player.
##
## The [ChatterGroupManager] drives the lifecycle: it polls [method in_start_range]
## / [method outside_stop_range] against the player and calls [method run_chatter],
## [method on_left_stop_range] and [method interrupt].

enum OutOfRangeBehaviour {
	DO_NOTHING,        ## leave a running conversation alone when the player leaves
	STOP,              ## stop the conversation
	STOP_AND_RUN_NODE, ## stop, then play [member out_of_range_node]
}

## Saliency strategy for choosing which content this group runs. Matches the
## runner's own [enum YarnDialogueRunner.SaliencyStrategyType].
enum Saliency {
	RANDOM,
	FIRST,
	BEST,
	RANDOM_BEST_LEAST_RECENT,
	BEST_LEAST_RECENT,
}

## Start the conversation the moment the player enters [member start_radius],
## rather than after a random delay (used for player-involved chats).
@export var start_immediately_on_enter: bool = false
## Whether the primary conversation interrupts this group.
@export var interrupted_by_primary: bool = true

## show start/stop range spheres in the editor
@export var show_ranges_in_editor: bool = true:
	set(value):
		show_ranges_in_editor = value
		if Engine.is_editor_hint():
			_refresh_range_gizmos()

@export_group("Range")
## The player must be within this distance for the conversation to start.
@export var start_radius: float = 6.0
## The conversation stops (per [member out_of_range_behaviour]) once the player
## is at least this far away. Should be >= [member start_radius].
@export var stop_radius: float = 9.0

@export_group("Dialogue")
@export var dialogue_runner: YarnDialogueRunner
## The node (or node group) to run as this group's chatter.
@export var chatter_node: String = ""
@export var saliency: Saliency = Saliency.RANDOM_BEST_LEAST_RECENT
@export var out_of_range_behaviour: OutOfRangeBehaviour = OutOfRangeBehaviour.STOP
## Played when STOP_AND_RUN_NODE is set and the player walks away mid-conversation.
@export var out_of_range_node: String = ""


func _refresh_range_gizmos() -> void:
	for child in get_children():
		if child.name.begins_with("_RangeGizmo"):
			child.queue_free()
	if not show_ranges_in_editor:
		return
	for cfg in [[start_radius, Color(0.3, 0.9, 0.4, 0.12), "_RangeGizmoStart"],
			[stop_radius, Color(0.9, 0.35, 0.3, 0.08), "_RangeGizmoStop"]]:
		var mesh := SphereMesh.new()
		mesh.radius = cfg[0]
		mesh.height = cfg[0] * 2.0
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = cfg[1]
		mesh.material = mat
		var instance := MeshInstance3D.new()
		instance.name = cfg[2]
		instance.mesh = mesh
		add_child(instance)


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_range_gizmos()
		return

	if dialogue_runner != null:
		dialogue_runner.saliency_strategy = _map_saliency()


func _map_saliency() -> YarnDialogueRunner.SaliencyStrategyType:
	match saliency:
		Saliency.RANDOM:
			return YarnDialogueRunner.SaliencyStrategyType.RANDOM
		Saliency.FIRST:
			return YarnDialogueRunner.SaliencyStrategyType.FIRST
		Saliency.BEST:
			return YarnDialogueRunner.SaliencyStrategyType.BEST
		Saliency.BEST_LEAST_RECENT:
			return YarnDialogueRunner.SaliencyStrategyType.BEST_LEAST_RECENT
		_:
			return YarnDialogueRunner.SaliencyStrategyType.RANDOM_BEST_LEAST_RECENT


func is_running() -> bool:
	return dialogue_runner != null and dialogue_runner.is_running()


## Starts the chatter conversation. Awaitable: completes when the conversation
## ends (or returns immediately if it can't start).
func run_chatter() -> void:
	if dialogue_runner == null or chatter_node.is_empty():
		push_warning("ChatterGroup '%s': no runner or chatter node set" % name)
		return
	if dialogue_runner.is_running():
		push_warning("ChatterGroup '%s': can't start dialogue, runner is already running" % name)
		return
	dialogue_runner.start_dialogue(chatter_node)
	await dialogue_runner.dialogue_completed


## Stops the conversation immediately (used when the primary dialogue starts).
func interrupt() -> void:
	if dialogue_runner != null and dialogue_runner.is_running():
		await dialogue_runner.stop_dialogue()


func in_start_range(player_position: Vector3) -> bool:
	return global_position.distance_to(player_position) <= start_radius


func outside_stop_range(player_position: Vector3) -> bool:
	return global_position.distance_to(player_position) >= stop_radius


## Reaction to the player leaving the stop radius mid-conversation.
func on_left_stop_range() -> void:
	match out_of_range_behaviour:
		OutOfRangeBehaviour.DO_NOTHING:
			pass
		OutOfRangeBehaviour.STOP:
			if dialogue_runner != null and dialogue_runner.is_running():
				await dialogue_runner.stop_dialogue()
		OutOfRangeBehaviour.STOP_AND_RUN_NODE:
			if dialogue_runner == null:
				return
			if dialogue_runner.is_running():
				await dialogue_runner.stop_dialogue()
			if not out_of_range_node.is_empty():
				dialogue_runner.start_dialogue(out_of_range_node)
				await dialogue_runner.dialogue_completed
