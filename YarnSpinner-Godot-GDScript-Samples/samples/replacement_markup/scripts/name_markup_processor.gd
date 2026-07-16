class_name NameMarkupProcessor
extends YarnAttributeMarkerProcessor

## Colours and bolds an entity's name based on a palette, so important people
## stand out in a line. Handles both [code][name]Bob[/name][/code] (entity taken
## from the wrapped text) and [code][name=bob]I[/name][/code] (entity taken from
## the marker's value).

## Entity name to display colour. Keys are lowercased for case-insensitive lookup.
var entities := {
	"player": Color(0.3647059, 0.78039217, 0.53333336),
	"alice": Color(0.38431373, 0.5294118, 0.7921569),
	"bob": Color(0.8901961, 0.62352943, 0.25882354),
}


func process_replacement_marker(
	marker: YarnMarkupAttribute,
	child_builder: Array,
	_child_attributes: Array,
	_locale_code: String
) -> ReplacementMarkerResult:
	var entity := marker.try_get_string_property("name")
	if entity.is_empty():
		entity = child_builder[0]

	var invisible := 0
	var key := entity.to_lower()
	if entities.has(key):
		var colour: Color = entities[key]
		var prefix := "[color=#%s][b]" % colour.to_html(false)
		var suffix := "[/b][/color]"
		child_builder[0] = "%s%s%s" % [prefix, child_builder[0], suffix]
		# The wrapped tags add no visible characters.
		invisible = prefix.length() + suffix.length()

	return ReplacementMarkerResult.new([], invisible)
