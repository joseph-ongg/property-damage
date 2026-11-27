class_name GameplayAshRemnant
extends Node2D

const ASHES_SPRITE: Texture2D = preload("res://gameplay/msd/art/item_ashes.svg")
const GRAVITY: float = 1100.0
const MAX_STEP_DISTANCE: float = 4.0

var settled: bool = false
var _fall_speed: float = 0.0
var _pile_width: float = 32.0
var _support_width: float = 32.0
var _support: CollisionObject2D
var _support_last_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("visual_ash_remnants")


func initialize_from_item(item: GameplayInteractableItem) -> void:
	_pile_width = clampf(item.hit_size.x, 32.0, 56.0)
	_support_width = _pile_width
	var base_offset := item.hit_offset + Vector2(0.0, item.hit_size.y * 0.5)
	if item is GameplayBurnableProp and not (item is GameplayWorldItem):
		base_offset = Vector2(0.0, 13.0)
		_pile_width = clampf(item.width, 32.0, 56.0)
		_support_width = _pile_width
	global_position = item.to_global(base_offset)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if settled:
		if _has_valid_support():
			var movement := _support.global_position - _support_last_position
			global_position += movement
			_support_last_position = _support.global_position
			return
		_support = null
		settled = false
		_fall_speed = 0.0

	_fall_speed += GRAVITY * delta
	var distance := _fall_speed * delta
	var steps := clampi(ceili(absf(distance) / MAX_STEP_DISTANCE), 1, 256)
	var step := distance / float(steps)
	for _i in range(steps):
		var hit := _find_landing(global_position.y - 1.0, global_position.y + step + 1.0)
		if not hit.is_empty():
			global_position.y = float(hit.position.y)
			_support = hit.collider as CollisionObject2D
			_support_last_position = _support.global_position
			_fall_speed = 0.0
			settled = true
			return
		global_position.y += step


func _find_landing(from_y: float, to_y: float) -> Dictionary:
	var space := get_world_2d().direct_space_state
	var half_width := minf(_support_width * 0.4, 20.0)
	var nearest: Dictionary = {}
	for offset in [-half_width, 0.0, half_width]:
		var from := Vector2(global_position.x + offset, from_y)
		var to := Vector2(global_position.x + offset, to_y)
		var query := PhysicsRayQueryParameters2D.create(from, to, 1)
		var hit := space.intersect_ray(query)
		if hit.is_empty() or hit.normal.y >= -0.5 or not hit.collider is CollisionObject2D:
			continue
		if nearest.is_empty() or hit.position.y < nearest.position.y:
			nearest = hit
	return nearest


func _has_valid_support() -> bool:
	return is_instance_valid(_support) and not _support.is_queued_for_deletion() \
		and (_support.collision_layer & 1) != 0


func _draw() -> void:
	var half := _pile_width * 0.5
	draw_rect(Rect2(-half, -5.0, _pile_width, 5.0), Color("514c4a"))
	draw_rect(Rect2(-half + 4.0, -10.0, _pile_width - 8.0, 5.0), Color("68605a"))
	draw_texture_rect(ASHES_SPRITE, Rect2(-16.0, -32.0, 32.0, 32.0), false)
