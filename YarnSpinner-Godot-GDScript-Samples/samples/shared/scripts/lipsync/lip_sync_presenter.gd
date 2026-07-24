class_name LipSyncPresenter
extends YarnDialoguePresenter
## Drives a character's mouth shapes from `.lipsync` timeline data, running in
## parallel with the voice-over presenter for the same line.
##
## This mirrors Unity's TextureLipSyncView! It is a presenter (not a node on the
## character)so the runner calls [method run_line] on it at the same time as
## the voice-over presenter. It loads the line's `.lipsync` file, waits the same
## pre-roll as the voice presenter so mouth and audio start together, then steps
## the mouth shape off elapsed time until the timeline ends.

## The voice-over presenter, read only to match its pre-start delay.
@export var voice_presenter: YarnVoiceOverPresenter
## Folder containing the per-locale LipSync-<locale> subfolders.
@export_dir var lipsync_base_path := "res://samples/voice_over_3d/dialogue/audio"
## Prefix of each locale subfolder, e.g. "LipSync-" -> LipSync-en, LipSync-de.
@export var lipsync_subdir_prefix := "LipSync-"
## Locale to fall back to when the current locale has no lipsync file.
@export var default_locale := "en"

# MouthShape enum values are A,B,C,D,E,F,G,H,TH,X (0..9); the .lipsync files
# name shapes by these letters.
const _SHAPES := {
	"A": LipSyncedTextureGroup.MouthShape.A,
	"B": LipSyncedTextureGroup.MouthShape.B,
	"C": LipSyncedTextureGroup.MouthShape.C,
	"D": LipSyncedTextureGroup.MouthShape.D,
	"E": LipSyncedTextureGroup.MouthShape.E,
	"F": LipSyncedTextureGroup.MouthShape.F,
	"G": LipSyncedTextureGroup.MouthShape.G,
	"H": LipSyncedTextureGroup.MouthShape.H,
	"TH": LipSyncedTextureGroup.MouthShape.TH,
	"X": LipSyncedTextureGroup.MouthShape.X,
}


func run_line(line: YarnLine, token: YarnCancellationToken = null) -> void:
	var character := _find_character(line.character_name)
	if character == null:
		return

	var frames := _load_lipsync(line.line_id)
	if frames.is_empty():
		return

	# Match the voice presenter's pre-roll so the mouth and audio line up.
	var delay: float = voice_presenter.wait_time_before_start if voice_presenter != null else 0.0
	if delay > 0.0:
		await YarnAsync.wait(self, delay)
		if _skipped(token) or not is_instance_valid(character):
			return

	var duration: float = frames[-1]["time"]
	var elapsed := 0.0
	while elapsed < duration:
		if _skipped(token):
			break
		character.set_mouth_shape(_evaluate(frames, elapsed))
		await get_tree().process_frame
		if not is_inside_tree() or not is_instance_valid(character):
			return
		elapsed += get_process_delta_time()

	character.set_mouth_shape(LipSyncedTextureGroup.MouthShape.X)


func _skipped(token: YarnCancellationToken) -> bool:
	return token != null and token.is_next_content_requested


## Finds the speaking character node by name (matches the line's character).
func _find_character(character_name: String) -> SimpleCharacter:
	if character_name.is_empty():
		return null
	# Search from the scene root (current_scene when running normally, otherwise
	# this presenter's owning scene root).
	var scene := get_tree().current_scene
	if scene == null:
		scene = owner
	if scene == null:
		return null
	if scene.name == character_name:
		return scene as SimpleCharacter
	return scene.find_child(character_name, true, false) as SimpleCharacter


## Reads the `.lipsync` file for a line as an ordered list of {time, shape}.
## Prefers the current locale's folder and falls back to [member default_locale].
func _load_lipsync(line_id: String) -> Array:
	var bare := line_id.trim_prefix("line:")
	var path := _lipsync_path(bare, TranslationServer.get_locale())
	if not FileAccess.file_exists(path):
		path = _lipsync_path(bare, default_locale)
	if not FileAccess.file_exists(path):
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var frames: Array = []
	while not file.eof_reached():
		var raw := file.get_line().strip_edges()
		if raw.is_empty() or raw.begins_with("#") or raw.begins_with("audio:"):
			continue
		var parts := raw.split("\t", false)
		if parts.size() < 2:
			continue
		if not _SHAPES.has(parts[1]):
			continue
		frames.append({"time": parts[0].to_float(), "shape": _SHAPES[parts[1]]})
	return frames


func _lipsync_path(bare_id: String, locale: String) -> String:
	return lipsync_base_path.path_join(lipsync_subdir_prefix + locale).path_join(bare_id + ".lipsync")


## Step function: the shape of the last frame whose time has been reached.
func _evaluate(frames: Array, time: float) -> LipSyncedTextureGroup.MouthShape:
	var shape: LipSyncedTextureGroup.MouthShape = frames[0]["shape"]
	for frame in frames:
		if frame["time"] > time:
			break
		shape = frame["shape"]
	return shape
