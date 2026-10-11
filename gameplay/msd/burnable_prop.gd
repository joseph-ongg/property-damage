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

var scorched: bool = false
var flash_left: float = 0.0
var _time: float = 0.0


func can_pick_up(player: GameplayPlayer) -> bool:
	return carried_by == null and not flying and global_position.distance_to(player.global_position) <= pickup_radius


func pick_up(player: GameplayPlayer) -> bool:
	if not can_pick_up(player):
		return false
	carried_by = player
	flying = false
	flight_velocity = Vector2.ZERO
	global_position = player.global_position + Vector2(player.facing * 22, -22)
	picked_up_by.emit(player.player_index)
	return true


func throw_from(player: GameplayPlayer) -> bool:
	if carried_by != player:
		return false
	carried_by = null
	global_position = player.global_position + Vector2(player.facing * 27, -22)
	flight_velocity = Vector2(float(player.facing) * throw_speed + player.velocity.x * 0.35, throw_lift)
	flying = true
	thrown_by.emit(player.player_index)
	return true


func _physics_process(delta: float) -> void:
	if carried_by != null:
		global_position = carried_by.global_position + Vector2(carried_by.facing * 22, -22)
	elif flying:
		var next_position := global_position + flight_velocity * delta
		flight_velocity.y += drop_gravity * delta
		# Real StaticBody2D geometry supports floor, table and one-way shelf landings.
		var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, 13), next_position + Vector2(0, 13), 1)
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and flight_velocity.y >= 0.0 and hit.position.y >= global_position.y:
			global_position = Vector2(next_position.x, hit.position.y - 13)
			flight_velocity = Vector2.ZERO
			flying = false
		else:
			global_position = next_position
		if global_position.y >= 485.0:
			global_position.y = 485.0
			flight_velocity = Vector2.ZERO
			flying = false
		global_position.x = clampf(global_position.x, 24.0, 936.0)
		if global_position.x <= 24.0 or global_position.x >= 936.0:
			flight_velocity.x = -flight_velocity.x * 0.4


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
