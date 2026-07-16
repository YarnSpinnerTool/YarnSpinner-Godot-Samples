class_name CharacterAppearance
extends Node

## Recolours a character's gradient material per instance. In Simple mode the
## top (fade) colour is derived from the base colour with an HSV shift; in
## Complex mode both colours are set explicitly. The material is duplicated so
## each character can have its own colours without affecting the shared
## resource.

enum Mode { SIMPLE, COMPLEX }

@export var base_color := Color(0.886, 0.503, 0.489)
@export var fade_color := Color(0.943, 0.232, 0.0)
@export var mode := Mode.SIMPLE
## surface index on the character mesh that carries the gradient material
@export var surface_index := 1
## the character mesh; auto-found among the parent's descendants if left empty
@export var mesh: MeshInstance3D

const _SATURATION_OFFSET := -0.3
const _VALUE_OFFSET := 0.25


func _ready() -> void:
	if mesh == null:
		mesh = _find_gradient_mesh(get_parent())
	apply()


## Sets explicit base and fade colours (Complex mode).
func set_appearance(base: Color, fade: Color) -> void:
	base_color = base
	fade_color = fade
	mode = Mode.COMPLEX
	apply()


func apply() -> void:
	if mesh == null:
		return
	var source := _current_material()
	if source == null:
		return

	var top := fade_color
	var bottom := base_color
	if mode == Mode.SIMPLE:
		top = _simple_tint(base_color)
		bottom = base_color

	var unique := source.duplicate() as ShaderMaterial
	unique.set_shader_parameter("Top_Colour", top)
	unique.set_shader_parameter("Bottom_Colour", bottom)
	mesh.set_surface_override_material(surface_index, unique)


func _current_material() -> ShaderMaterial:
	var material := mesh.get_surface_override_material(surface_index)
	if material == null and mesh.mesh != null and surface_index < mesh.mesh.get_surface_count():
		material = mesh.mesh.surface_get_material(surface_index)
	return material as ShaderMaterial


## Brightens and desaturates the base colour for the Simple-mode fade.
func _simple_tint(base: Color) -> Color:
	return Color.from_hsv(
		base.h,
		clampf(base.s + _SATURATION_OFFSET, 0.0, 1.0),
		clampf(base.v + _VALUE_OFFSET, 0.0, 1.0),
		base.a)


func _find_gradient_mesh(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	if node is MeshInstance3D:
		var candidate := node as MeshInstance3D
		var material := candidate.get_surface_override_material(surface_index)
		if material == null and candidate.mesh != null and surface_index < candidate.mesh.get_surface_count():
			material = candidate.mesh.surface_get_material(surface_index)
		if material is ShaderMaterial and (material as ShaderMaterial).get_shader_parameter("Bottom_Colour") != null:
			return candidate
	for child in node.get_children():
		var found := _find_gradient_mesh(child)
		if found != null:
			return found
	return null
