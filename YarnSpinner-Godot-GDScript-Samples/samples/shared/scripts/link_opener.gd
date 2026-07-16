class_name LinkOpener
extends Node

## Opens external links clicked in a dialogue line. The markup parser turns Yarn
## [code][link][/code] markup into RichTextLabel [code][url][/code] tags; this
## connects the label's meta_clicked so an external link opens in the browser.

## the label that renders dialogue text; auto-found among siblings if unset
@export var rich_text_label: RichTextLabel


func _ready() -> void:
	if rich_text_label == null:
		rich_text_label = _find_label(get_parent())
	if rich_text_label != null and not rich_text_label.meta_clicked.is_connected(_on_meta_clicked):
		rich_text_label.meta_clicked.connect(_on_meta_clicked)


func _on_meta_clicked(meta: Variant) -> void:
	var url := str(meta)
	if url.is_empty():
		return
	if not (url.begins_with("http://") or url.begins_with("https://")):
		url = "https://" + url
	OS.shell_open(url)


func _find_label(node: Node) -> RichTextLabel:
	if node == null:
		return null
	for child in node.get_children():
		if child is RichTextLabel:
			return child
		var found := _find_label(child)
		if found != null:
			return found
	return null
