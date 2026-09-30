# onboarding/burn-box/material_grid.gd
class_name MaterialGrid
extends Node2D

# The plumbing below is done: grid size, the tick timer, and the Inspector "Tuning" group.
# Everything else is yours to design: how cells are stored, what materials exist,
# what "burning" means, and the functions other teams call. See README, Step 1.

@export var width := 64
@export var height := 36
@export var cell_size := 16

@export_group("Tuning")
@export var tick_rate := 0.1:
	set(value):
		tick_rate = value
		if is_node_ready():
			$TickTimer.wait_time = value
# TODO: add your own knobs here (spread chances, burn times, ...) so Design can tune them.


func _ready() -> void:
	# TODO: set up your cell storage, then fill the default map.
	$TickTimer.wait_time = tick_rate
	$TickTimer.timeout.connect(_on_tick)
	$TickTimer.start()


func _on_tick() -> void:
	pass  # TODO: one simulation step.


# ---------- Public API: other teams call these ----------
# TODO (Step 1): add every public function and signal here, with typed arguments,
# a return type, and a "##" comment saying what it does. Bodies can stay `pass` until Step 2.


# ---------- Helpers (plumbing, keep or change freely) ----------

func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height


func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local := to_local(world_pos)
	return Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))


func neighbors(x: int, y: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := x + offset.x
		var ny := y + offset.y
		if in_bounds(nx, ny):
			result.append(Vector2i(nx, ny))
	return result
