extends Node

## Registers the sample's replacement-marker processors so the line presenter
## renders every marker in the yarn files: the demo tags palette ([b], [i],
## [u], [s], [custom], [fancy]), [style], [obscurity], [name] and the sprite
## markers ([lightning], [ice], [heart], [fire]).

@export var dialogue_runner: YarnDialogueRunner


func _ready() -> void:
	if dialogue_runner == null:
		dialogue_runner = _find_runner(get_tree().current_scene)
	if dialogue_runner == null:
		push_error("replacement markup setup: no dialogue runner found")
		return

	var obscurity := ObscurityMarkupProcessor.new()
	obscurity.matched_replacement = false
	var name_processor := NameMarkupProcessor.new()

	for presenter in dialogue_runner.get_presenters():
		if presenter is YarnLinePresenter:
			var font_size := _label_font_size(presenter)

			var palette_processor := YarnPaletteMarkerProcessor.new(_build_demo_tags_palette(font_size))
			palette_processor.register_with_line_provider(presenter)

			var style_processor := YarnStyleMarkerProcessor.new()
			# H2 style: <size=1.5em><b><#4080FF>
			style_processor.styles["h2"] = {
				"start": "[font_size=%d][b][color=#4080ff]" % roundi(font_size * 1.5),
				"end": "[/color][/b][/font_size]",
			}
			presenter.register_marker_processor("style", style_processor)

			var sprite := SpriteMarkupProcessor.new()
			sprite.icon_size = font_size

			presenter.register_marker_processor("obscurity", obscurity)
			presenter.register_marker_processor("name", name_processor)
			for marker in ["lightning", "ice", "heart", "fire"]:
				presenter.register_marker_processor(marker, sprite)


## Builds the demo tags palette used by the sample's yarn files.
func _build_demo_tags_palette(font_size: int) -> YarnMarkupPalette:
	var palette := YarnMarkupPalette.new()
	palette.add_basic_marker("b", false, Color.WHITE, true)
	palette.add_basic_marker("i", false, Color.WHITE, false, true)
	palette.add_basic_marker("u", false, Color.WHITE, false, false, true)
	palette.add_basic_marker("s", false, Color.WHITE, false, false, false, true)
	palette.add_basic_marker("custom", true, Color(0.13172704, 0.6886792, 0.0), true, false, true)
	# fancy wraps its text in yellow double-size brackets, so one visible
	# character leads the text and two are added overall.
	palette.add_custom_marker(
		"fancy",
		"[color=#ffff00][font_size=%d][lb]" % (font_size * 2),
		"[rb][/font_size][/color]",
		1,
		2
	)
	return palette


func _label_font_size(presenter: YarnLinePresenter) -> int:
	var label := presenter.text_label
	if label == null:
		var labels := presenter.find_children("*", "RichTextLabel", true, false)
		if not labels.is_empty():
			label = labels.front()
	if label == null:
		return 16
	return label.get_theme_font_size("normal_font_size")


func _find_runner(node: Node) -> YarnDialogueRunner:
	if node == null:
		return null
	if node is YarnDialogueRunner:
		return node
	for child in node.get_children():
		var found := _find_runner(child)
		if found != null:
			return found
	return null
