## Directional magic attack with swept first-hit item/player damage.
## Furniture ignition uses the same bridge and MaterialGrid as Spark.
class_name GameplayMagicBolt
extends Node2D

const RULES: GameplayTuning = preload("res://gameplay/tuning/gameplay_balance.tres")

signal hit(target_name: String, caster_index: int)

# Hand-painted pixel texture frames replace the old soft circles/rectangles.
const SPELL_SIGILS: Array[Texture2D] = [
    preload("res://gameplay/presentation/assets/spell_sigil_0.png"),
    preload("res://gameplay/presentation/assets/spell_sigil_1.png"),
    preload("res://gameplay/presentation/assets/spell_sigil_2.png"),
    preload("res://gameplay/presentation/assets/spell_sigil_3.png"),
]

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
var attack_kind: String = "mage"


func initialize(player: GameplayPlayer) -> void:
	caster_index = player.player_index
	direction = player.facing
	speed = RULES.bolt_speed * (1.3 if player.character_kind == "ninja" else 1.0)
	lifetime = 0.14 if player.character_kind == "werewolf" else RULES.bolt_lifetime
	attack_kind = player.character_kind
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
	var combat_hit := _hit_combat_target(room, before, global_position)
	if not combat_hit.is_empty():
		_resolved = true
		hit.emit(combat_hit, caster_index)
		queue_free()
		return
	var furniture_hit := _ignite_furniture(room, before, global_position) if attack_kind == "mage" else ""
	if not furniture_hit.is_empty():
		_resolved = true
		hit.emit(furniture_hit, caster_index)
		queue_free()
		return
	if not obstruction.is_empty():
		# Solid world geometry wins over proximity-based prop effects. Without
		# this guard a 32px book scorch radius could damage a book *through*
		# a wall immediately behind the projectile impact point.
		queue_free()
		return
	if room.experimental_books_enabled:
		for book: GameplayBurnableProp in room.get_node("Books").get_children():
			# A nearby book still needs a clear ray from bolt to object.
			# This prevents the scorch radius from reaching through walls.
			if global_position.distance_to(book.global_position) <= book.spark_radius and _has_clear_path(book.global_position) and book.try_scorch(global_position, caster_index):
				_resolved = true
				hit.emit("BOOKS", caster_index)
				break
	if not _resolved and room.experimental_appliances_enabled:
		var pc: GameplayAppliance = room.get_node("Appliances/ComputerDevice")
		# The computer has a larger trigger radius than books, so checking
		# only the bolt's travel segment is insufficient near a thin wall.
		if global_position.distance_to(pc.global_position) <= 49.0 and _has_clear_path(pc.global_position) and pc.receive_spark(global_position, caster_index):
			_resolved = true
			hit.emit("COMPUTER", caster_index)
	if _resolved or not obstruction.is_empty() or _age >= lifetime or global_position.x < 8 or global_position.x > 952:
		queue_free()
	else:
		queue_redraw()


func _hit_combat_target(room: Node, start: Vector2, finish: Vector2) -> String:
	var nearest_distance := INF
	var target: Node = null
	var impact_point: Vector2 = finish
	for item: GameplayInteractableItem in get_tree().get_nodes_in_group("interactable_items"):
		if not room.is_ancestor_of(item) or item.destroyed_item or is_inf(item.max_hp):
			continue
		var point: Variant = _segment_rect_hit(start, finish, item.hit_rect())
		if point != null and start.distance_to(point) < nearest_distance:
			nearest_distance = start.distance_to(point)
			target = item
			impact_point = point
	for player: GameplayPlayer in [room.get_node("Player1"), room.get_node("Player2")]:
		if player.player_index == caster_index or player.in_cover:
			continue
		var player_rect := Rect2(player.global_position + Vector2(-16, -45), Vector2(32, 60))
		var point: Variant = _segment_rect_hit(start, finish, player_rect)
		if point != null and start.distance_to(point) < nearest_distance:
			nearest_distance = start.distance_to(point)
			target = player
			impact_point = point
	if target is GameplayInteractableItem:
		var item := target as GameplayInteractableItem
		item.take_damage(RULES.item_hit_damage, caster_index)
		if attack_kind == "mage":
			# Ignite the Simulation grid at the actual impact cell, not only
			# the item's separate condition overlay.
			var bridge := room.get_node_or_null("FireBridge") as GameplayFireBridge
			if bridge != null:
				bridge.ignite_world(impact_point)
			item.ignite()
		return item.item_name
	if target is GameplayPlayer:
		var attacker: GameplayPlayer = room.get_node("Player%d" % caster_index)
		(target as GameplayPlayer).take_damage(attacker.attack_damage)
		return "P%d" % (target as GameplayPlayer).player_index
	return ""


func _segment_rect_hit(start: Vector2, finish: Vector2, rect: Rect2) -> Variant:
	if rect.has_point(start):
		return start
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	var closest: Variant = null
	for i in 4:
		var point: Variant = Geometry2D.segment_intersects_segment(start, finish, corners[i], corners[(i + 1) % 4])
		if point != null and (closest == null or start.distance_to(point) < start.distance_to(closest)):
			closest = point
	return closest


func _ignite_furniture(room: Node, start: Vector2, finish: Vector2) -> String:
	var layer: GameplayFurnitureFireLayer = room.get_node_or_null("MaterialGrid/FurnitureFireLayer") as GameplayFurnitureFireLayer
	var bridge: GameplayFireBridge = room.get_node_or_null("FireBridge") as GameplayFireBridge
	if layer == null or bridge == null:
		return ""
	var grid: MaterialGrid = bridge.grid() as MaterialGrid
	if grid == null:
		return ""
	# Sample at half-cell intervals so a fast projectile cannot skip a thin leg.
	var steps := maxi(1, ceili(start.distance_to(finish) / (float(grid.cell_size) * 0.5)))
	for step in range(steps + 1):
		var point := start.lerp(finish, float(step) / float(steps))
		var cell := bridge.world_to_cell(point)
		if layer.covers_cell(cell) and bridge.ignite_world(point):
			return layer.furniture_at_cell(cell)
	return ""


func _has_clear_path(target: Vector2) -> bool:
	# Use the same layer-1 world collision the projectile already respects.
	# Player bodies live on layer 2 and cannot block one another's magic.
	var sight_ray := PhysicsRayQueryParameters2D.create(global_position, target, 1)
	return get_world_2d().direct_space_state.intersect_ray(sight_ray).is_empty()


func _draw() -> void:
	if attack_kind == "ninja":
		# An original small four-point metal shuriken, not a Mage fireball.
		draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(3, -3), Vector2(9, 0), Vector2(3, 3), Vector2(0, 8), Vector2(-3, 3), Vector2(-9, 0), Vector2(-3, -3)]), Color("#a6d7e5"))
		draw_circle(Vector2.ZERO, 2.0, Color("#344e6e"))
		return
	if attack_kind == "werewolf":
		# Provisional close-range claw effect until Design finalizes the attack.
		for offset in [-5.0, 0.0, 5.0]:
			draw_line(Vector2(-7.0, offset - 7.0), Vector2(7.0, offset + 7.0), Color("#f2d2ad"), 2.0)
		return
	# Jewel-colored original arcane sigil adds the cast VFX without
	# changing fireball collisions, physics, or upstream Simulation logic.
	if _age < 0.25:
		var sigil: Texture2D = SPELL_SIGILS[int(_age * 17.0) % SPELL_SIGILS.size()]
		draw_texture(sigil, Vector2(-32, -32), Color(1, 1, 1, 0.72 - 1.7 * _age))
	var frame: Texture2D = FIRE_FRAMES[int(_age * 14.0) % FIRE_FRAMES.size()]
	# Flip the comet trail when flying to the left. Pixel edges stay crisp.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(direction), 1.0))
	draw_texture(frame, Vector2(-12, -8))
	draw_set_transform(Vector2.ZERO)
