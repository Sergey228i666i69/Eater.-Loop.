extends Node2D
class_name FoodCrumbsEffect

## Количество крошек при поедании.
@export var crumb_count_min: int = 5
@export var crumb_count_max: int = 7

## Физические параметры падения крошек.
@export var gravity: float = 2600.0
@export var horizontal_speed_min: float = -110.0
@export var horizontal_speed_max: float = 110.0
@export var initial_vertical_speed_min: float = -180.0
@export var initial_vertical_speed_max: float = -40.0
@export var rotation_speed_min: float = -12.0
@export var rotation_speed_max: float = 12.0
@export var lifetime: float = 0.55
@export var fade_ratio: float = 0.4

class Crumb:
	var sprite: Sprite2D
	var velocity: Vector2
	var angular_velocity: float


var _crumbs: Array[Crumb] = []
var _elapsed: float = 0.0


static func create_and_spawn(source_sprite: Sprite2D, spawn_pos: Vector2, parent_node: Node) -> Node2D:
	if source_sprite == null or source_sprite.texture == null or parent_node == null:
		return null
	var script: GDScript = load("res://levels/minigames/feeding/food/food_crumbs_effect.gd")
	var effect: Node2D = script.new() as Node2D
	if effect == null:
		return null
	effect.name = "FoodCrumbsEffect"
	effect.z_index = 20
	parent_node.add_child(effect)
	effect.global_position = spawn_pos
	effect.call("setup_from_sprite", source_sprite)
	return effect


func setup_from_sprite(source_sprite: Sprite2D) -> void:
	if source_sprite == null or source_sprite.texture == null:
		return
	
	var tex := source_sprite.texture
	var tex_size := tex.get_size()
	if tex_size.x <= 1.0 or tex_size.y <= 1.0:
		return

	var count := randi_range(crumb_count_min, crumb_count_max)
	var sample_points := _sample_texture_points(tex, count)
	
	var base_scale := source_sprite.scale.abs()
	var min_dim := minf(tex_size.x, tex_size.y)
	
	for i in range(sample_points.size()):
		var center_pt: Vector2 = sample_points[i]
		var slice_size := randf_range(min_dim * 0.05, min_dim * 0.10)
		var half_slice := slice_size * 0.5
		var region_x := clampf(center_pt.x - half_slice, 0.0, tex_size.x - slice_size)
		var region_y := clampf(center_pt.y - half_slice, 0.0, tex_size.y - slice_size)
		
		var crumb_sprite := Sprite2D.new()
		crumb_sprite.texture = tex
		crumb_sprite.region_enabled = true
		crumb_sprite.region_rect = Rect2(region_x, region_y, slice_size, slice_size)
		crumb_sprite.centered = true
		crumb_sprite.modulate = source_sprite.modulate * source_sprite.self_modulate
		
		var crumb_scale_factor := randf_range(0.35, 0.65)
		crumb_sprite.scale = base_scale * crumb_scale_factor
		crumb_sprite.rotation = randf() * TAU
		
		var jitter_pos := Vector2(randf_range(-14.0, 14.0), randf_range(-10.0, 10.0))
		crumb_sprite.position = jitter_pos
		add_child(crumb_sprite)
		
		var crumb := Crumb.new()
		crumb.sprite = crumb_sprite
		crumb.velocity = Vector2(
			randf_range(horizontal_speed_min, horizontal_speed_max),
			randf_range(initial_vertical_speed_min, initial_vertical_speed_max)
		)
		crumb.angular_velocity = randf_range(rotation_speed_min, rotation_speed_max)
		_crumbs.append(crumb)


func _sample_texture_points(tex: Texture2D, target_count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var img := tex.get_image()
	var width := int(tex.get_width())
	var height := int(tex.get_height())
	
	if img != null and width > 0 and height > 0:
		var attempts := 0
		var max_attempts := target_count * 15
		while points.size() < target_count and attempts < max_attempts:
			attempts += 1
			var px := randi() % width
			var py := randi() % height
			var alpha := img.get_pixel(px, py).a
			if alpha > 0.3:
				points.append(Vector2(px, py))
	
	# Fallback если текстура не имеет Image или прозрачна
	while points.size() < target_count:
		var fx := randf_range(width * 0.25, width * 0.75) if width > 0 else 0.0
		var fy := randf_range(height * 0.25, height * 0.75) if height > 0 else 0.0
		points.append(Vector2(fx, fy))
	
	return points


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	
	var fade_start := lifetime * (1.0 - fade_ratio)
	var alpha_factor: float = 1.0
	if _elapsed > fade_start and lifetime > fade_start:
		alpha_factor = clampf(1.0 - (_elapsed - fade_start) / (lifetime - fade_start), 0.0, 1.0)
	
	for crumb in _crumbs:
		if crumb.sprite == null or not is_instance_valid(crumb.sprite):
			continue
		crumb.velocity.y += gravity * delta
		crumb.sprite.position += crumb.velocity * delta
		crumb.sprite.rotation += crumb.angular_velocity * delta
		crumb.sprite.modulate.a = alpha_factor
