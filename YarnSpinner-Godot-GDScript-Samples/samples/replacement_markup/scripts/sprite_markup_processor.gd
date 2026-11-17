class_name SpriteMarkupProcessor
extends YarnAttributeMarkerProcessor


const SPRITE_SHEET := "res://samples/replacement_markup/sprites/effects.png"
const SPRITE_CELL := 46

var buff := Color(0.0, 0.7320416, 1.0)
var debuff := Color(1.0, 0.64280593, 0.0)
var icon_size := 32

var _sprites := {
	"lightning": {"column": 1, "buff": false},
	"ice": {"column": 0, "buff": true},
	"heart": {"column": 3, "buff": true},
	"fire": {"column": 2, "buff": false},
}


func process_replacement_marker(
	marker: YarnMarkupAttribute,
	child_builder: Array,
	child_attributes: Array,
	_locale_code: String
) -> ReplacementMarkerResult:
	var marker_name := marker.name.to_lower()
	if not _sprites.has(marker_name):
		var diag := MarkupDiagnostic.new("was unable to find a matching sprite for %s" % marker.name)
		return ReplacementMarkerResult.new([diag], 0)

	var sprite: Dictionary = _sprites[marker_name]
	var colour := buff if sprite["buff"] else debuff
	var image := "[img width=%d height=%d region=%d,0,%d,%d]%s[/img]" % [
		icon_size, icon_size, sprite["column"] * SPRITE_CELL, SPRITE_CELL, SPRITE_CELL, SPRITE_SHEET
	]

	var prefix := YarnMarkupParser.brackets_to_tags("[b][lb][color=#%s]%s" % [colour.to_html(false), image])
	var suffix := YarnMarkupParser.brackets_to_tags("[/color][rb][/b]")

	child_builder[0] = "%s%s%s" % [prefix, child_builder[0], suffix]

	var visible_prefix := 2
	var visible_suffix := 1
	var invisible := (prefix.length() - visible_prefix) + (suffix.length() - visible_suffix)

	for i in range(child_attributes.size()):
		var attr: YarnMarkupAttribute = child_attributes[i]
		child_attributes[i] = attr.shift(visible_prefix)

	return ReplacementMarkerResult.new([], invisible)
