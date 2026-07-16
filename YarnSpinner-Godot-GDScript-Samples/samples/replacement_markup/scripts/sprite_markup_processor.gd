class_name SpriteMarkupProcessor
extends YarnAttributeMarkerProcessor

## Replaces the lightning/ice/heart/fire markers with an icon from the effects
## sprite sheet and a coloured, bracketed label, e.g.
## [code][lightning]zap damage[/lightning][/code] becomes "[⚡zap damage]" with
## the icon and text tinted by effect type.

const SPRITE_SHEET := "res://samples/replacement_markup/sprites/effects.png"
const SPRITE_CELL := 46

## Colour for beneficial effects.
var buff := Color(0.0, 0.7320416, 1.0)
## Colour for harmful effects.
var debuff := Color(1.0, 0.64280593, 0.0)
## Rendered icon size in pixels; the setup script matches it to the font size.
var icon_size := 32

# Sheet column and tint for each handled marker.
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

	# Bold brackets around everything, the effect colour on the icon and the
	# wrapped text.
	var prefix := "[b][lb][color=#%s]%s" % [colour.to_html(false), image]
	var suffix := "[/color][rb][/b]"

	child_builder[0] = "%s%s%s" % [prefix, child_builder[0], suffix]

	# The bracket and the icon are the only visible characters added at the
	# front, and the closing bracket at the end; the rest is bbcode.
	var visible_prefix := 2
	var visible_suffix := 1
	var invisible := (prefix.length() - visible_prefix) + (suffix.length() - visible_suffix)

	for i in range(child_attributes.size()):
		var attr: YarnMarkupAttribute = child_attributes[i]
		child_attributes[i] = attr.shift(visible_prefix)

	return ReplacementMarkerResult.new([], invisible)
