@tool
class_name ChatterGroup
extends AttachToNodes


enum OutOfRangeBehaviour {
	DO_NOTHING,
	STOP,
	STOP_AND_RUN_NODE,
}

enum Saliency {
	RANDOM,
	FIRST,
	BEST,
	RANDOM_BEST_LEAST_RECENT,
	BEST_LEAST_RECENT,
}

@export var start_immediately_on_enter: bool = false
@export var interrupted_by_primary: bool = true

@export var show_ranges_in_editor: bool = true:
	set(value):
		show_ranges_in_editor = value
		if Engine.is_editor_hint():
			_refresh_range_gizmos()

@export_group("Range")
@export var start_radius: float = 6.0
@export var stop_radius: float = 9.0

@export_group("Dialogue")
@export var dialogue_runner: YarnDialogueRunner
@export var chatter_node: String = ""
@export var saliency: Saliency = Saliency.RANDOM_BEST_LEAST_RECENT
@export var out_of_range_behaviour: OutOfRangeBehaviour = OutOfRangeBehaviour.STOP
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
		dialogue_runner.set_content_saliency_strategy(_map_saliency())


func _map_saliency() -> YarnSaliencyStrategy:
	match saliency:
		Saliency.RANDOM:
			return YarnSaliencyStrategy.YarnRandomSaliencyStrategy.new()
		Saliency.FIRST:
			return YarnSaliencyStrategy.YarnFirstSaliencyStrategy.new()
		Saliency.BEST:
			return YarnSaliencyStrategy.YarnBestSaliencyStrategy.new()
		Saliency.BEST_LEAST_RECENT:
			return YarnSaliencyStrategy.YarnBestLeastRecentlyViewedSaliencyStrategy.new()
		_:
			return YarnSaliencyStrategy.YarnRandomBestLeastRecentlyViewedSaliencyStrategy.new()


func is_running() -> bool:
	return dialogue_runner != null and dialogue_runner.is_running()


func run_chatter() -> void:
	if dialogue_runner == null or chatter_node.is_empty():
		push_warning("ChatterGroup '%s': no runner or chatter node set" % name)
		return
	if dialogue_runner.is_running():
		push_warning("ChatterGroup '%s': can't start dialogue, runner is already running" % name)
		return
	await dialogue_runner.run_dialogue(chatter_node)


func interrupt() -> void:
	if dialogue_runner != null and dialogue_runner.is_running():
		await dialogue_runner.stop_dialogue()


func in_start_range(player_position: Vector3) -> bool:
	return global_position.distance_to(player_position) <= start_radius


func outside_stop_range(player_position: Vector3) -> bool:
	return global_position.distance_to(player_position) >= stop_radius


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
				await dialogue_runner.run_dialogue(out_of_range_node)
