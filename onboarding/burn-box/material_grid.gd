# onboarding/burn-box/material_grid.gd
class_name MaterialGrid
extends Node2D

signal cell_changed(x: int, y: int, material: int)  # fired by set_cell and ignite
signal ticked  # fired after every sim step

# Order matches the tile index table in the onboarding doc. Add new materials at the end.
enum Cell { AIR, WOOD, STONE, OIL, ASH, WATER }

@export var width := 64
@export var height := 36
@export var cell_size := 16

@export_group("Tuning")
@export var wood_spread_chance := 0.3
@export var oil_spread_chance := 0.7
@export var wood_burn_ticks := 12
@export var oil_burn_ticks := 6
@export var tick_rate := 0.1:
	set(value):
		tick_rate = value
		if is_node_ready():
			$TickTimer.wait_time = value

var grid: Array = []  # grid[x][y] -> Cell. Burning cells keep their material.
var burn_age: Array = []  # burn_age[x][y] -> 0 if not burning, else ticks spent burning


func _ready() -> void:
	for x in width:
		grid.append([])
		burn_age.append([])
		for y in height:
			grid[x].append(Cell.AIR)
			burn_age[x].append(0)
	DefaultMap.fill(self)
	$TickTimer.wait_time = tick_rate
	$TickTimer.timeout.connect(_on_tick)
	$TickTimer.start()


func _on_tick() -> void:
	var next_grid := grid.duplicate(true)
	var next_age := burn_age.duplicate(true)
	for x in width:
		for y in height:
			pass  # TODO (Ethan): read from grid/burn_age, write only to next_grid/next_age.
			# 1. Burning cell next to water -> goes out.
			# 2. Burning cell -> try to ignite each flammable neighbor (randf() < spread_chance(neighbor)).
			# 3. Burning cell -> age += 1; at burn_ticks(material), becomes ASH and stops burning.
	grid = next_grid
	burn_age = next_age
	ticked.emit()


# ---------- Public API: Gameplay, Design, and the rest of this team call these ----------
# Do not rename or change these without a PM's OK; other teams build against them.

func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height


func get_cell(x: int, y: int) -> int:
	return grid[x][y]


func set_cell(x: int, y: int, material: int) -> void:
	if not in_bounds(x, y):
		return
	grid[x][y] = material
	burn_age[x][y] = 0
	cell_changed.emit(x, y, material)


func is_burning(x: int, y: int) -> bool:
	return burn_age[x][y] > 0


func ignite(x: int, y: int) -> void:
	if in_bounds(x, y) and is_flammable(grid[x][y]) and not is_burning(x, y):
		burn_age[x][y] = 1
		cell_changed.emit(x, y, grid[x][y])


func is_flammable(material: int) -> bool:
	return material == Cell.WOOD or material == Cell.OIL


func spread_chance(material: int) -> float:
	match material:
		Cell.WOOD:
			return wood_spread_chance
		Cell.OIL:
			return oil_spread_chance
	return 0.0


func burn_ticks(material: int) -> int:
	match material:
		Cell.WOOD:
			return wood_burn_ticks
		Cell.OIL:
			return oil_burn_ticks
	return 0


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
