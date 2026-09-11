class_name LinkOpener
extends Node

## Opens links clicked in a dialogue line. The markup parser turns Yarn
## [code][link][/code] markup into RichTextLabel [code][url][/code] tags; this
## connects the label's meta_clicked so a link opens its sample file or browser.

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
	if url.begins_with("http://") or url.begins_with("https://"):
		OS.shell_open(url)
		return
	var local_path := _find_project_file("res://samples", url)
	if not local_path.is_empty():
		OS.shell_open(ProjectSettings.globalize_path(local_path))
		return
	OS.shell_open("https://" + url)


func _find_project_file(directory: String, file_name: String) -> String:
	var dir := DirAccess.open(directory)
	if dir == null:
		return ""
	for file in dir.get_files():
		if file == file_name:
			return directory.path_join(file)
	for child in dir.get_directories():
		if child.begins_with("."):
			continue
		var found := _find_project_file(directory.path_join(child), file_name)
		if not found.is_empty():
			return found
	return ""


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
