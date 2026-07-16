class_name WeightedSaliencyStrategy
extends YarnSaliencyStrategy

## Weighted-random saliency selection: writers decide how likely each piece of
## salient content is to be chosen.
##
## It rolls a single large dice whose number of sides equals the combined weight
## of all the still-valid candidates. Each candidate's weight is the range of
## values it occupies on the dice; the candidate whose range contains the roll is
## selected.
##
## A node gets its weight from a "weight" header (e.g. "weight: 3"). A line group
## option gets its weight from a "#weight:N" line-metadata tag. Missing, zero or
## negative weights are treated as a weight of 1.
##
## Because failing content is dropped before the dice is built, the exact chance
## of any one piece of content varies from run to run depending on which other
## candidates currently pass their conditions.

const WEIGHT_KEY := "weight"


func select_candidate(candidates: Array[Dictionary], context: Dictionary) -> int:
	var vm: Variant = context.get("vm")

	# Each entry: the original candidate index plus its inclusive [min, max] range
	# on the dice.
	var ranges: Array[Dictionary] = []
	var dice_size := 0

	for i in range(candidates.size()):
		var candidate := candidates[i]

		# Drop anything that failed a condition.
		if candidate.get("conditions_failed", 0) > 0:
			continue

		var weight := _weight_for(candidate, vm)
		ranges.append({"index": i, "min": dice_size, "max": dice_size + weight - 1})
		dice_size += weight

	# No valid content: signal that nothing should run.
	if ranges.is_empty():
		return -1

	# Roll the dice and return whichever candidate's range contains it.
	var roll := randi_range(0, dice_size - 1)
	for entry in ranges:
		if roll >= entry.min and roll <= entry.max:
			return entry.index

	return -1


# This strategy keeps no state, so selection needs no follow-up.
func on_candidate_selected(_candidate: Dictionary, _context: Dictionary) -> void:
	pass


## Resolves a candidate's weight, defaulting to 1 when it is unset, unparseable,
## zero or negative.
func _weight_for(candidate: Dictionary, vm: Variant) -> int:
	var content_id: String = candidate.get("content_id", "")
	var weight_string := ""

	if vm != null and not content_id.is_empty():
		if candidate.get("content_type", ContentType.LINE) == ContentType.NODE:
			# Node group: the weight lives in a node header.
			weight_string = vm.get_header_value(content_id, WEIGHT_KEY)
		elif vm.program != null:
			# Line group: the weight lives in a "#weight:N" line-metadata tag.
			weight_string = vm.program.get_metadata_value(content_id, WEIGHT_KEY + ":")

	weight_string = weight_string.strip_edges()
	if not weight_string.is_valid_int():
		return 1

	return maxi(1, weight_string.to_int())
