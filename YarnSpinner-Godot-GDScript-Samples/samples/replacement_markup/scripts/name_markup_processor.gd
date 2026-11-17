class_name NameMarkupProcessor
extends YarnAttributeMarkerProcessor


var entities: Dictionary[String, Color] = {}


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
		var prefix := YarnMarkupParser.brackets_to_tags("[color=#%s][b]" % colour.to_html(false))
		var suffix := YarnMarkupParser.brackets_to_tags("[/b][/color]")
		child_builder[0] = "%s%s%s" % [prefix, child_builder[0], suffix]
		invisible = prefix.length() + suffix.length()

	return ReplacementMarkerResult.new([], invisible)
