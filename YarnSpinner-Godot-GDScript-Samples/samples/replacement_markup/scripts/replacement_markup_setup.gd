extends Node

## Registers the sample's replacement-marker processors so the line presenter
## renders every marker in the yarn files: the demo tags palette ([b], [i],
## [u], [s], [custom], [fancy]), [style], [obscurity], [name] and the sprite
## markers ([lightning], [ice], [heart], [fire]).

@export var dialogue_runner: YarnDialogueRunner
@export var demo_tags_palette: YarnMarkupPalette
@export var styles: Dictionary[String, Dictionary] = {}
@export var name_colours: Dictionary[String, Color] = {}
@export var buff_colour := Color.WHITE
@export var debuff_colour := Color.WHITE
@export var icon_size := 24
@export var matched_obscurity := false


func _ready() -> void:
	if dialogue_runner == null:
		push_error("replacement markup setup: no dialogue runner set")
		return

	var palette_processor := YarnPaletteMarkerProcessor.new(demo_tags_palette)

	var style_processor := YarnStyleMarkerProcessor.new()
	style_processor.styles = styles

	var obscurity := ObscurityMarkupProcessor.new()
	obscurity.matched_replacement = matched_obscurity

	var name_processor := NameMarkupProcessor.new()
	name_processor.entities = name_colours

	var sprite := SpriteMarkupProcessor.new()
	sprite.buff = buff_colour
	sprite.debuff = debuff_colour
	sprite.icon_size = icon_size

	for presenter in dialogue_runner.get_presenters():
		if presenter is YarnLinePresenter:
			palette_processor.register_with_line_provider(presenter)
			presenter.register_marker_processor("style", style_processor)
			presenter.register_marker_processor("obscurity", obscurity)
			presenter.register_marker_processor("name", name_processor)
			for marker in ["lightning", "ice", "heart", "fire"]:
				presenter.register_marker_processor(marker, sprite)
