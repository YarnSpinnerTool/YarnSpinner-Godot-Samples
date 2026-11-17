class_name WeightedSaliencyStrategy
extends YarnSaliencyStrategy


const WEIGHT_KEY := "weight"


func select_candidate(candidates: Array[Dictionary], context: Dictionary) -> int:
	var vm: Variant = context.get("vm")

	var ranges: Array[Dictionary] = []
	var dice_size := 0

	for i in range(candidates.size()):
		var candidate := candidates[i]

		if candidate.get("conditions_failed", 0) > 0:
			continue

		var weight := _weight_for(candidate, vm)
		ranges.append({"index": i, "min": dice_size, "max": dice_size + weight - 1})
		dice_size += weight

	if ranges.is_empty():
		return -1

	var roll := randi_range(0, dice_size - 1)
	for entry in ranges:
		if roll >= entry.min and roll <= entry.max:
			return entry.index

	return -1


func on_candidate_selected(_candidate: Dictionary, _context: Dictionary) -> void:
	pass


func _weight_for(candidate: Dictionary, vm: Variant) -> int:
	var content_id: String = candidate.get("content_id", "")
	var weight_string := ""

	if vm != null and not content_id.is_empty():
		if candidate.get("content_type", ContentType.LINE) == ContentType.NODE:
			weight_string = vm.get_header_value(content_id, WEIGHT_KEY)
		elif vm.program != null:
			weight_string = vm.program.get_metadata_value(content_id, WEIGHT_KEY + ":")

	weight_string = weight_string.strip_edges()
	if not weight_string.is_valid_int():
		return 1

	return maxi(1, weight_string.to_int())
