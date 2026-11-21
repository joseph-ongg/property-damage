## Directional magic attack with swept first-hit item/player damage.
## Furniture ignition uses the same bridge and MaterialGrid as Spark.
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
## Design: Ninja attacks appear as shurikens in *both* arenas.
## Temporary procedural marker until Art Team provides the sprite.
var projectile_kind: String = "fireball"
var _age: float = 0.0
var _resolved: bool = false


func initialize(player: GameplayPlayer) -> void:
	caster_index = player.player_index
	match player.character_kind:
		"ninja":
			projectile_kind = "shuriken"  # Design-defined, sprite not delivered
		"werewolf":
			projectile_kind = "werewolf_unapproved"  # "Shoots cloth?" is not approved
		_:
			projectile_kind = "fireball"  # Wizard actual Art Team texture
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
	var combat_hit := _hit_combat_target(room, before, global_position)
	if not combat_hit.is_empty():
		_resolved = true
		hit.emit(combat_hit, caster_index)
		queue_free()
		return
	var furniture_hit := _ignite_furniture(room, before, global_position)
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
	for item: GameplayInteractableItem in get_tree().get_nodes_in_group("interactable_items"):
		if not room.is_ancestor_of(item) or item.destroyed_item or is_inf(item.max_hp):
			continue
		var point: Variant = _segment_rect_hit(start, finish, item.hit_rect())
		if point != null and start.distance_to(point) < nearest_distance:
			nearest_distance = start.distance_to(point)
			target = item
	for player: GameplayPlayer in [room.get_node("Player1"), room.get_node("Player2")]:
		if player.player_index == caster_index:
			continue
		var player_rect := Rect2(player.global_position + Vector2(-16, -45), Vector2(32, 60))
		var point: Variant = _segment_rect_hit(start, finish, player_rect)
		if point != null and start.distance_to(point) < nearest_distance:
			nearest_distance = start.distance_to(point)
			target = player
	if target is GameplayInteractableItem:
		# Preserve the original Living Room books' scorch art/signal when a
		# direct item hit is introduced by Austin's more general hit system.
		# try_scorch already consumes 1 HP; don't apply damage a second time.
		if target is GameplayBurnableProp and (target as GameplayBurnableProp).item_name == "BOOKS":
			var book: GameplayBurnableProp = target as GameplayBurnableProp
			if book.try_scorch(book.global_position, caster_index):
				return book.item_name
		(target as GameplayInteractableItem).take_damage(1.0, caster_index)
		return (target as GameplayInteractableItem).item_name
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
	if projectile_kind == "shuriken" or projectile_kind == "werewolf_unapproved":
		# Without approved attack art, show a small literal '?' placeholder.
		# Shared damage, item hit ordering and projectile movement stay intact.
		var base := Color("#667c91") if projectile_kind == "shuriken" else Color("#8c8074")
		draw_rect(Rect2(-10, -10, 20, 20), base)
		draw_rect(Rect2(-10, -10, 20, 20), Color("#f2f1e9"), false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(-4.5, 5.0), "?",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#fdfaf1"))
		return
	var frame: Texture2D = FIRE_FRAMES[int(_age * 14.0) % FIRE_FRAMES.size()]
	# Wizard flame texture remains the unchanged Art Team image.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(direction), 1.0))
	draw_texture(frame, Vector2(-12, -8))
	draw_set_transform(Vector2.ZERO)
