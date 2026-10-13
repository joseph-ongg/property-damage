## OPTIONAL book-scorching mock-up based on the design team's tentative book mechanic.
## Pure local visual response. Does not alter MaterialGrid or claim real damage.
class_name GameplayBurnableProp
extends Node2D

signal scorched_by(player_index: int)
signal picked_up_by(player_index: int)
signal thrown_by(player_index: int)

@export_range(14.0, 70.0, 1.0) var spark_radius: float = 32.0
@export var width: float = 31.0
@export var pickup_radius: float = 56.0
@export var throw_speed: float = 340.0
@export var throw_lift: float = -230.0
@export var drop_gravity: float = 930.0

var carried_by: GameplayPlayer = null
var flying: bool = false
var flight_velocity: Vector2 = Vector2.ZERO
# The last platform/floor that physically supports a *thrown* book. Static
# designer-placed props stay parked until first picked up or thrown.
var _support: CollisionObject2D = null
var _support_last_position: Vector2 = Vector2.ZERO
var _watch_resting: bool = false
var _rest_slide_speed: float = 0.0

var scorched: bool = false
var flash_left: float = 0.0
var _time: float = 0.0


func can_pick_up(player: GameplayPlayer) -> bool:
	return carried_by == null and not flying and is_instance_valid(player) and global_position.distance_to(player.global_position) <= pickup_radius and GameplayInteractionLOS.has_path(player, global_position)


func pick_up(player: GameplayPlayer) -> bool:
	if not can_pick_up(player):
		return false
	carried_by = player
	flying = false
	_reset_resting()
	flight_velocity = Vector2.ZERO
	global_position = player.global_position + Vector2(player.facing * 22, -22)
	picked_up_by.emit(player.player_index)
	return true


func throw_from(player: GameplayPlayer) -> bool:
	if carried_by != player:
		return false
	carried_by = null
	_reset_resting()
	global_position = player.global_position + Vector2(player.facing * 27, -22)
	flight_velocity = Vector2(float(player.facing) * throw_speed + player.velocity.x * 0.35, throw_lift)
	flying = true
	thrown_by.emit(player.player_index)
	return true


func _physics_process(delta: float) -> void:
	if carried_by != null:
		global_position = carried_by.global_position + Vector2(carried_by.facing * 22, -22)
	elif flying:
		_step_flight(delta)
	elif _watch_resting:
		_step_resting(delta)


func _reset_resting() -> void:
	_support = null
	_support_last_position = Vector2.ZERO
	_watch_resting = false
	_rest_slide_speed = 0.0


func _settle(support: CollisionObject2D, momentum: float) -> void:
	_support = support
	_support_last_position = support.global_position if is_instance_valid(support) else Vector2.ZERO
	_watch_resting = true
	# Retain a little horizontal throw momentum, then quickly dissipate it.
	# This allows a marginally supported book to slide over an edge naturally.
	_rest_slide_speed = clampf(momentum * 0.35, -125.0, 125.0)
	flight_velocity = Vector2.ZERO
	flying = false


func _bottom_support() -> Dictionary:
	# The painted stack has a 13px bottom offset; sample several points so
	# partial contact at a tabletop edge is valid while remaining on it.
	var half_width: float = minf(width * 0.45, 14.0)
	var nearest: Dictionary = {}
	for offset in [-half_width * 0.55, 0.0, half_width * 0.55]:
		var foot := global_position + Vector2(offset, 13)
		var hit := _world_ray(foot + Vector2.UP * 3.0, foot + Vector2.DOWN * 3.0, false)
		if not hit.is_empty() and hit.normal.y < -0.5:
			if nearest.is_empty() or hit.position.y < nearest.position.y:
				nearest = hit
	return nearest


func _step_resting(delta: float) -> void:
	# Carried by a moving StaticBody2D, but NEVER blindly teleport through
	# another solid collider. This also handles an elevator reaching a roof.
	var moved := Vector2.ZERO
	if is_instance_valid(_support):
		moved = _support.global_position - _support_last_position
		_support_last_position = _support.global_position
	else:
		_support = null
	if absf(_rest_slide_speed) > 0.01:
		moved.x += _rest_slide_speed * delta
		_rest_slide_speed = move_toward(_rest_slide_speed, 0.0, 420.0 * delta)
	if absf(moved.x) > 0.001:
		var hit := _side_hit(global_position, moved.x, 0.0)
		if hit.is_empty():
			global_position.x = clampf(global_position.x + moved.x, 24.0, 936.0)
		else:
			global_position.x = hit.position.x - signf(moved.x) * (minf(width * 0.45, 14.0) + 0.5)
			_rest_slide_speed = 0.0
	if absf(moved.y) > 0.001:
		if moved.y < 0.0:
			var roof := _vertical_hit(global_position, moved.y, false)
			if not roof.is_empty():
				# Ceiling wins over upward-moving support; if the platform keeps
				# going, the book loses its support and falls next physics step.
				global_position.y = roof.position.y + 13.5
			else:
				global_position.y += moved.y
		else:
			global_position.y += moved.y
	var contact: Dictionary = _bottom_support()
	if not contact.is_empty():
		_support = contact.collider as CollisionObject2D
		_support_last_position = _support.global_position if is_instance_valid(_support) else Vector2.ZERO
		global_position.y = contact.position.y - 13.0
		return
	# Stop following a vanished support and re-enable gravity. No arbitrary
	# impulse from a teleporting platform, which could cause another tunnel.
	flight_velocity = Vector2(_rest_slide_speed, 0.0)
	_reset_resting()
	flying = true


func _side_hit(at: Vector2, displacement: float, y_shift: float) -> Dictionary:
	if absf(displacement) < 0.0001:
		return {}
	var direction := signf(displacement)
	var edge: float = direction * minf(width * 0.45, 14.0)
	var closest: Dictionary = {}
	for dy in [-8.0, 0.0, 10.0]:
		# Check current and destination-height envelopes, to catch diagonal
		# impacts where a ray at the starting height would pass above a wall.
		for vertical_shift in [0.0, y_shift]:
			var origin := at + Vector2(edge, dy + vertical_shift)
			var hit := _world_ray(origin, origin + Vector2(displacement, 0.0), true)
			if not hit.is_empty() and hit.normal.x * direction < -0.5:
				if closest.is_empty() or absf(hit.position.x - origin.x) < absf(closest.position.x - origin.x):
					closest = hit
	return closest


func _vertical_hit(at: Vector2, displacement: float, downward: bool) -> Dictionary:
	if absf(displacement) < 0.0001:
		return {}
	var half_width := minf(width * 0.45, 14.0)
	var edge_y := 13.0 if downward else -13.0
	var closest: Dictionary = {}
	for dx in [-half_width * 0.55, 0.0, half_width * 0.55]:
		var origin := at + Vector2(dx, edge_y)
		var hit := _world_ray(origin, origin + Vector2(0.0, displacement), not downward)
		if hit.is_empty():
			continue
		if (downward and hit.normal.y < -0.5) or (not downward and hit.normal.y > 0.5):
			if closest.is_empty() or absf(hit.position.y-origin.y) < absf(closest.position.y-origin.y):
				closest = hit
	return closest


func _step_flight(delta: float) -> void:
	# A single horizontal ray misses a wall when a fast diagonal book starts
	# above it, and a book shot at a roof used to pass straight through.
	# Sub-step the *original* displacement, sampling swept leading edges.
	# Ordinary 340px/s throws cost only 1-2 steps; large debug velocities
	# still get bounded continuous coverage rather than tunnelling.
	var motion := flight_velocity * delta
	flight_velocity.y += drop_gravity * delta
	var steps := clampi(int(ceilf(maxf(absf(motion.x), absf(motion.y)) / 4.0)), 1, 256)
	var part := motion / float(steps)
	for _step in steps:
		var at := global_position
		var candidate := at + part
		var lateral := _side_hit(at, part.x, part.y)
		if not lateral.is_empty():
			candidate.x = lateral.position.x - signf(part.x) * (minf(width * 0.45, 14.0) + 0.5)
			flight_velocity.x = -flight_velocity.x * 0.25
			if absf(flight_velocity.x) < 50.0:
				flight_velocity.x = 0.0
			# A single impact consumes the remaining sideways distance from
			# this frame. Otherwise later substeps reuse the old positive dx,
			# start on the wall surface, and can tunnel through it.
			part.x = 0.0
		var vertical := _vertical_hit(Vector2(candidate.x, at.y), part.y, part.y >= 0.0)
		if not vertical.is_empty():
			if part.y >= 0.0:
				candidate.y = vertical.position.y - 13.0
				global_position = candidate
				_settle(vertical.collider as CollisionObject2D, flight_velocity.x)
				break
			candidate.y = vertical.position.y + 13.5
			flight_velocity.y = 0.0
			part.y = 0.0
		global_position = candidate
		# Retain the demo-specific safe bottom bound. Other team's final arena
		# may replace this clamp with its own actual floor collider.
		if global_position.y >= 485.0:
			global_position.y = 485.0
			_settle(null, flight_velocity.x)
			break
		if global_position.x < 24.0:
			global_position.x = 24.0
			if flight_velocity.x < 0.0:
				flight_velocity.x *= -0.25
		elif global_position.x > 936.0:
			global_position.x = 936.0
			if flight_velocity.x > 0.0:
				flight_velocity.x *= -0.25


func _world_ray(origin: Vector2, finish: Vector2, ignore_one_way: bool) -> Dictionary:
	var space := get_world_2d().direct_space_state
	var excluded: Array[RID] = []
	for _pass in 5:
		var query := PhysicsRayQueryParameters2D.create(origin, finish, 1, excluded)
		var result: Dictionary = space.intersect_ray(query)
		if result.is_empty() or not ignore_one_way:
			return result
		var collider := result.collider as CollisionObject2D
		if collider == null:
			return result
		var owner_id: int = collider.shape_find_owner(int(result.shape))
		var owner: Object = collider.shape_owner_get_owner(owner_id)
		if owner is CollisionShape2D and (owner as CollisionShape2D).one_way_collision:
			excluded.append(collider.get_rid())
			continue
		return result
	return {}


func try_scorch(target: Vector2, player_index: int) -> bool:
	if scorched or target.distance_to(global_position) > spark_radius:
		return false
	scorched = true
	flash_left = 1.3
	queue_redraw()
	scorched_by.emit(player_index)
	return true


func _process(delta: float) -> void:
	_time += delta
	if flash_left > 0.0:
		flash_left = maxf(0.0, flash_left - delta)
		queue_redraw()
	elif not scorched and Engine.get_process_frames() % 6 == 0:
		queue_redraw()


func _draw() -> void:
	var half := width * 0.5
	draw_ellipse_shadow(half)
	var cover: Color = Color("424348") if scorched else Color("bf8c57")
	var paper: Color = Color("716b66") if scorched else Color("e4cda4")
	# Three offset piles, drawn in 2px pixel clusters for crisp scales.
	for i in range(3):
		var left: float = -half + i * 5.0
		var bottom: float = 11 - i * 8.0
		draw_rect(Rect2(left, bottom - 6, width - 5, 7), cover)
		draw_rect(Rect2(left + 3, bottom - 4, width - 10, 3), paper)
		draw_rect(Rect2(left, bottom - 7, width - 5, 2), Color("6b494d") if scorched else Color("7a6774"))
	if not scorched:
		# A one-pixel glint indicates this piece can react to magic.
		var glint := Color(0.97, 0.86, 0.62, 0.40 + 0.30 * sin(_time * 2.5))
		draw_rect(Rect2(-1, -21, 2, 2), glint)
	elif flash_left > 0.0:
		var strength := minf(flash_left / 0.5, 1.0)
		for i in 5:
			var x := -12.0 + float(i) * 6.0
			var rise := (1.3 - flash_left) * (11.0 + float(i % 3) * 5.0)
			draw_rect(Rect2(Vector2(x, -18 - rise).round(), Vector2(3, 3)), Color(0.98, 0.50 + 0.06 * i, 0.22, strength))
		draw_rect(Rect2(-half - 3, -8, width + 5, 20), Color(1.0, 0.45, 0.16, flash_left * 0.18), false, 2.0)


func draw_ellipse_shadow(half: float) -> void:
	# Built from opaque pixel strips, rather than blurry circles.
	draw_rect(Rect2(-half + 1, 12, width - 2, 3), Color(0.10, 0.10, 0.12, 0.47))
