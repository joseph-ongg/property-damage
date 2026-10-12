## Directional prototype magic attack. No health, mana or damage scores.
## Remote scorch only; the team's Spark/MaterialGrid interface is untouched.
class_name GameplayMagicBolt
extends Node2D

signal hit(target_name: String, caster_index: int)

# Hand-painted pixel texture frames replace the old soft circles/rectangles.
const FIRE_FRAMES: Array[Texture2D] = [
	preload("res://gameplay/msd/art/fireball_0.png"),
	preload("res://gameplay/msd/art/fireball_1.png"),
	preload("res://gameplay/msd/art/fireball_2.png"),
	preload("res://gameplay/msd/art/fireball_3.png"),
	preload("res://gameplay/msd/art/fireball_4.png"),
	preload("res://gameplay/msd/art/fireball_5.png"),
]

@export var speed: float = 395.0
@export var lifetime: float = 1.45

var direction: int = 1
var caster_index: int = 1
var _age: float = 0.0
var _resolved: bool = false


func initialize(player: GameplayPlayer) -> void:
	caster_index = player.player_index
	direction = player.facing
	global_position = player.global_position + Vector2(direction * 19, -7)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _resolved:
		return
	_age += delta
	var before: Vector2 = global_position
	var after := before + Vector2(float(direction) * speed * delta, 0)
	# Check actual world collision geometry for a projectile-blocking obstacle.
	var ray := PhysicsRayQueryParameters2D.create(before, after, 1)
	var obstruction := get_world_2d().direct_space_state.intersect_ray(ray)
	global_position = after if obstruction.is_empty() else obstruction.position
	var room := get_parent().get_parent()
	if room.experimental_books_enabled:
		for book: GameplayBurnableProp in room.get_node("Books").get_children():
			if book.try_scorch(global_position, caster_index):
				_resolved = true
				hit.emit("BOOKS", caster_index)
				break
	if not _resolved and room.experimental_appliances_enabled:
		var pc: GameplayAppliance = room.get_node("Appliances/ComputerDevice")
		if pc.receive_spark(global_position, caster_index):
			_resolved = true
			hit.emit("COMPUTER", caster_index)
	if _resolved or not obstruction.is_empty() or _age >= lifetime or global_position.x < 8 or global_position.x > 952:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var frame: Texture2D = FIRE_FRAMES[int(_age * 14.0) % FIRE_FRAMES.size()]
	# Flip the comet trail when flying to the left. Pixel edges stay crisp.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(direction), 1.0))
	draw_texture(frame, Vector2(-12, -8))
	draw_set_transform(Vector2.ZERO)
