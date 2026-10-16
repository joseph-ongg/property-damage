## Subtle world-space guides to remaining optional demo objectives.
## Does not interact with physics, the fire grid, or quest state.
extends Node2D

@export var pulse_rate: float = 2.5
@onready var shards: Node2D = get_parent().get_node("Shards")
@onready var braziers: Node2D = get_parent().get_node("Braziers")
@onready var player1: GameplayPlayer = get_parent().get_node("Player1")
@onready var player2: GameplayPlayer = get_parent().get_node("Player2")

var _time: float = 0.0
var _redraw_delay: float = 0.0


func remaining_shards() -> int:
	var count := 0
	for shard: GameplayEmberShard in shards.get_children():
		if not shard.taken:
			count += 1
	return count


func remaining_braziers() -> int:
	var count := 0
	for brazier: GameplayEmberBrazier in braziers.get_children():
		if not brazier.lit:
			count += 1
	return count


func _process(delta: float) -> void:
	_time += delta
	_redraw_delay += delta
	if _redraw_delay > 0.06:
		_redraw_delay = 0.0
		queue_redraw()


func _draw() -> void:
	var alpha := 0.66 + 0.20 * sin(_time * pulse_rate)
	for shard: GameplayEmberShard in shards.get_children():
		if shard.taken:
			continue
		var center: Vector2 = shard.position + Vector2(0, -24)
		var color := Color(1.0, 0.85, 0.53, alpha)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -5), center + Vector2(4, 0),
			center + Vector2(0, 5), center + Vector2(-4, 0)]), color)
	for brazier: GameplayEmberBrazier in braziers.get_children():
		if brazier.lit:
			continue
		var cup: Vector2 = brazier.position + Vector2(0, -18)
		var color := Color(1.0, 0.56, 0.33, alpha)
		if is_brazier_targetable(brazier):
			color = Color(0.74, 1.0, 0.69, alpha)
			draw_arc(cup, 18, 0, TAU, 24, color, 2.0)
		var head := cup + Vector2(0, -30 - 2.0 * sin(_time * 2.0))
		draw_line(head + Vector2(-5, -3), head, color, 2.0)
		draw_line(head, head + Vector2(5, -3), color, 2.0)


func is_brazier_targetable(brazier: GameplayEmberBrazier) -> bool:
	if brazier.lit:
		return false
	var cup: Vector2 = brazier.global_position + Vector2(0, -18)
	for player: GameplayPlayer in [player1, player2]:
		var aim: Vector2 = player.global_position + Vector2(float(player.facing) * player.spark.reach, 0)
		if aim.distance_to(cup) <= brazier.ignition_radius:
			return true
	return false
