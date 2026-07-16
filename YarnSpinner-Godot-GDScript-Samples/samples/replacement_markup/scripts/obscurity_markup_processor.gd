class_name ObscurityMarkupProcessor
extends YarnAttributeMarkerProcessor

## Obscures a fraction of a line's non-whitespace characters at parse time,
## based on an [code]obscurity[/code] integer property. Used by the
## [code][obscurity=N]...[/obscurity][/code] marker to make a character's speech
## progressively easier to understand as the player learns their dialect.

## When true, a given source character always maps to the same replacement
## symbol, so repeated words stay recognisable.
var matched_replacement := true

var _replacement_chars := ["?", "^", ";", "*", "&", "#", "!", "@", "<", "_"]


func process_replacement_marker(
	marker: YarnMarkupAttribute,
	child_builder: Array,
	_child_attributes: Array,
	_locale_code: String
) -> ReplacementMarkerResult:
	var obscurity_prop := marker.try_get_property("obscurity")
	if obscurity_prop == null:
		var diag := MarkupDiagnostic.new("Missing the obscurity property, we cannot continue without it.")
		return ReplacementMarkerResult.new([diag], 0)

	var level := marker.try_get_int_property("obscurity")

	# 0 hides everything, 1 hides roughly two thirds, 2 hides about a quarter,
	# anything else leaves the text untouched.
	match level:
		0:
			_obscure(child_builder, 1.0)
		1:
			_obscure(child_builder, 0.67)
		2:
			_obscure(child_builder, 0.25)

	return ReplacementMarkerResult.new([], 0)


func _obscure(child_builder: Array, obscurity_fraction: float) -> void:
	var text: String = child_builder[0]

	var indices: Array[int] = []
	for i in text.length():
		if not _is_whitespace(text[i]):
			indices.append(i)

	# Fisher-Yates shuffle so the obscured characters are spread randomly.
	for i in range(indices.size() - 1):
		var swap := randi_range(i, indices.size() - 1)
		var temp := indices[i]
		indices[i] = indices[swap]
		indices[swap] = temp

	var threshold := int(indices.size() * obscurity_fraction)

	var chars: Array[String] = []
	for i in text.length():
		chars.append(text[i])

	for i in threshold:
		var j := indices[i]
		var source := chars[j].unicode_at(0)
		if matched_replacement:
			chars[j] = _replacement_chars[source % _replacement_chars.size()]
		else:
			chars[j] = _replacement_chars[randi_range(0, _replacement_chars.size() - 1)]

	child_builder[0] = "".join(chars)


func _is_whitespace(character: String) -> bool:
	return character == " " or character == "\t" or character == "\n" or character == "\r"
