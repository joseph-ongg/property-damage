## OPTIONAL book-scorching mock-up based on the design team's tentative book mechanic.
## Pure local visual response. Does not alter MaterialGrid or claim real damage.
class_name GameplayBurnableProp
extends Node2D

signal scorched_by(player_index: int)

@export_range(14.0, 70.0, 1.0) var spark_radius: float = 32.0
@export var width: float = 31.0

var scorched: bool = false
var flash_left: float = 0.0
var _time: float = 0.0


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
