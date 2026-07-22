class_name Slideshow
extends YarnDialoguePresenter

## Drives the projector slideshow for the Welcome intro. Doubles as a dialogue
## presenter and a command host: the <<start_slide>>, <<end_slide>> and
## <<clear_slide>> commands toggle slide mode, and while in slide mode lines
## spoken by SlideHeader / SlideBullet / SlideImage build up the slide instead
## of being shown as normal dialogue.

## title shown at the top of the slide
@export var header_label: Label
## body text; bullets are appended line by line
@export var body_label: Label
## slide image, shown in place of the body
@export var image: TextureRect
## the slide panel, hidden until a slide is being shown
@export var slide_panel: CanvasItem

## normal dialogue views to suppress while a slide is building, so slide-content
## lines aren't also shown as ordinary dialogue. These are removed from the
## runner during slide mode.
@export var override_presenters: Array[YarnDialoguePresenter] = []

## seconds to wait before restoring the normal views at the end of a slide
@export var delay_before_showing_new_slide: float = 0.5

## folder that slide images are loaded from, keyed by the name in the script
@export_dir var image_folder: String = "res://samples/welcome/images"

var _running_slideshow: bool = false


func _ready() -> void:
	_clear_slide()
	if slide_panel != null:
		slide_panel.visible = false


func on_dialogue_started() -> void:
	_clear_slide()


func _yarn_command_start_slide() -> void:
	if _running_slideshow:
		push_warning("slideshow: start_slide called while a slide was already being built")

	for presenter in override_presenters:
		if presenter != null and dialogue_runner != null:
			dialogue_runner.remove_presenter(presenter)
			presenter._set_presenter_visible(false)

	if slide_panel != null:
		slide_panel.visible = false

	_running_slideshow = true


func _yarn_command_end_slide() -> void:
	if not _running_slideshow:
		push_warning("slideshow: end_slide called while a slide was not being built")

	if delay_before_showing_new_slide > 0.0:
		await get_tree().create_timer(delay_before_showing_new_slide).timeout

	for presenter in override_presenters:
		if presenter != null and dialogue_runner != null:
			dialogue_runner.add_presenter(presenter)

	if slide_panel != null:
		slide_panel.visible = true

	_running_slideshow = false


func _yarn_command_clear_slide() -> void:
	_clear_slide()


func run_line(line: YarnLine, _token: YarnCancellationToken = null) -> void:
	# Slide-content lines only matter while a slide is being built; everything
	# else is left to the normal line presenter. Returns immediately, so this
	# presenter never holds the line open.
	if line.character_name.is_empty() or not _running_slideshow:
		return

	var text := line.text_without_character_name

	match line.character_name:
		"SlideHeader":
			_set_header(text)
		"SlideBullet":
			_add_bullet(text)
		"SlideImage":
			_set_image(text)


func _set_header(text: String) -> void:
	if header_label != null:
		header_label.visible = not text.is_empty()
		header_label.text = text


func _set_body(text: String) -> void:
	if not text.is_empty():
		_set_image("")
	if body_label != null:
		body_label.text = text
		body_label.visible = true


func _add_bullet(text: String) -> void:
	if body_label == null:
		return
	var result := body_label.text
	if result.is_empty():
		result = "• %s" % text
	else:
		result = "%s\n• %s" % [result, text]
	_set_body(result)


func _set_image(image_name: String) -> void:
	if not image_name.is_empty():
		_set_body("")
	if image == null:
		return
	var texture: Texture2D = null
	if not image_name.is_empty():
		texture = _load_image(image_name)
	image.texture = texture
	image.visible = texture != null


func _load_image(image_name: String) -> Texture2D:
	# Images are loaded by name from image_folder. A miss is reported and
	# skipped rather than treated as an error, so a slide referencing a
	# missing image still advances.
	for ext in [".png", ".jpg", ".jpeg", ".webp"]:
		var path := "%s/%s%s" % [image_folder, image_name, ext]
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is Texture2D:
				return res
	push_warning("slideshow: no image named \"%s\" in %s" % [image_name, image_folder])
	return null


func _clear_slide() -> void:
	_set_header("")
	_set_body("")
	_set_image("")
