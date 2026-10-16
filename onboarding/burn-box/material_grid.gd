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


## Chance per tick, per burning neighbor, for Wood to catch fire.
@export_range(0.0, 1.0) var wood_spread_chance: float = 0.15

## Chance per tick, per burning neighbor, for Oil to catch fire.
@export_range(0.0, 1.0) var oil_spread_chance: float = 0.35

## Seconds before burning Wood becomes Ash.
@export_range(0.1, 30.0) var wood_burn_time: float = 5.0

## Seconds before burning Oil becomes Ash.
@export_range(0.1, 30.0) var oil_burn_time: float = 2.0

# Cell data is indexed as [x][y]: column first, then row.
# Material and fire state are separate, so burning Wood is still Wood.
# Other systems should use the public API instead of modifying these arrays.
var materials: Array[Array] = []
var burning: Array[Array] = []

# Elapsed burn time in seconds. Stored now for the future fire simulation.
# No spreading or burn-time updates are implemented yet.
var burn_timers: Array[Array] = []


func _ready() -> void:
	# Ensure storage exists without clearing cells set before this node was ready.
	_initialize_cells_if_needed()
	# TODO: fill the default map after storage is initialized.
	$TickTimer.wait_time = tick_rate
	$TickTimer.timeout.connect(_on_tick)
	$TickTimer.start()


## Runs one simulation step: extinguish near Water, update burn time, then spread.
## Fires extinguished or burned out this tick do not spread.
func _on_tick() -> void:
	_extinguish_near_water()
	_update_burn_timers()
	_spread_fire()


## Extinguishes burning cells with Water in any of their four neighbors.
## Preserves both materials; diagonal Water has no effect.
func _extinguish_near_water() -> void:
	for x in width:
		for y in height:
			if not is_burning(x, y):
				continue

			# Water extinguishes fire in the four adjacent cells.
			for neighbor in neighbors(x, y):
				if get_cell_material(neighbor.x, neighbor.y) == Materials.WATER:
					extinguish(x, y)
					break


## Advances elapsed burn time by tick_rate for each burning cell.
## Wood and Oil use their own burn durations, then become Ash.
## Material changes go through set_cell_material to reset fire and emit signals.
func _update_burn_timers() -> void:
	for x in width:
		for y in height:
			if not burning[x][y]:
				continue

			# Track elapsed burning time in seconds.
			burn_timers[x][y] += tick_rate

			var cell_material: Materials = get_cell_material(x, y)
			var burn_duration: float

			if cell_material == Materials.WOOD:
				burn_duration = wood_burn_time
			elif cell_material == Materials.OIL:
				burn_duration = oil_burn_time
			else:
				continue

			# Setting the material also clears fire and resets the timer.
			if burn_timers[x][y] >= burn_duration:
				set_cell_material(x, y, Materials.ASH)


## Attempts to ignite flammable neighbors using the target material's spread chance.
## Each burning neighbor provides one attempt; targets next to Water are skipped.
## Applies new ignitions after scanning so fire spreads at most one cell per tick.
func _spread_fire() -> void:
	# Collect targets first so new fires cannot spread in the same tick.
	var cells_to_ignite: Array[Vector2i] = []

	for x in width:
		for y in height:
			if not is_burning(x, y):
				continue

			for target in neighbors(x, y):
				if is_burning(target.x, target.y):
					continue

				var target_material: Materials = get_cell_material(
					target.x, target.y
				)
				var chance: float

				# Spread probability depends on the target material.
				if target_material == Materials.WOOD:
					chance = wood_spread_chance
				elif target_material == Materials.OIL:
					chance = oil_spread_chance
				else:
					continue

				# Do not spread into cells protected by adjacent Water.
				var near_water: bool = false
				for neighbor in neighbors(target.x, target.y):
					if get_cell_material(
						neighbor.x, neighbor.y
					) == Materials.WATER:
						near_water = true
						break

				if near_water:
					continue

				if randf() < chance:
					if not cells_to_ignite.has(target):
						cells_to_ignite.append(target)

	# Apply ignition only after every existing fire has been checked.
	for cell in cells_to_ignite:
		ignite(cell.x, cell.y)


# ---------- Public API: other teams call these ----------

## Materials a cell can contain. Fire is a separate state.
enum Materials { AIR, WOOD, STONE, OIL, ASH, WATER }

## Emitted after a cell's material or burning state changes.
signal cell_changed(x: int, y: int)

## Sets a cell's material and resets its burning state; ignores out-of-bounds cells.
func set_cell_material(x: int, y: int, material_id: Materials) -> void:
	if not in_bounds(x, y):
		return
	_initialize_cells_if_needed()

	# Painting a material always clears fire and resets its burn timer.
	var material_changed : bool = materials[x][y] != material_id
	var burning_changed : bool = burning[x][y]
	materials[x][y] = material_id
	burning[x][y] = false
	burn_timers[x][y] = 0.0

	# Notify listeners only when the visible material or burning state changes.
	# Listeners can query the updated state through the public API.
	if material_changed or burning_changed:
		cell_changed.emit(x, y)

## Returns a cell's material, or AIR if out of bounds.
func get_cell_material(x: int, y: int) -> Materials:
	if not in_bounds(x, y):
		return Materials.AIR
	_initialize_cells_if_needed()
	return materials[x][y]

## Ignites a flammable cell; ignores out-of-bounds or already burning cells.
func ignite(x: int, y: int) -> void:
	if not in_bounds(x, y):
		return
	_initialize_cells_if_needed()

	if burning[x][y]:
		return

	# Only Wood and Oil are currently flammable.
	# Ignition changes fire state without replacing the original material.
	var cell_material: Materials = get_cell_material(x, y)
	if cell_material != Materials.WOOD and cell_material != Materials.OIL:
		return

	burning[x][y] = true
	burn_timers[x][y] = 0.0
	cell_changed.emit(x, y)


## Returns whether a cell is burning; returns false if out of bounds.
func is_burning(x: int, y: int) -> bool:
	if not in_bounds(x, y):
		return false
	_initialize_cells_if_needed()
	return burning[x][y]


## Extinguishes a cell without changing its material; ignores out-of-bounds cells.
func extinguish(x: int, y: int) -> void:
	if not in_bounds(x, y):
		return
	_initialize_cells_if_needed()

	if not burning[x][y]:
		return

	# Extinguishing preserves the material and resets the burn timer.
	burning[x][y] = false
	burn_timers[x][y] = 0.0
	cell_changed.emit(x, y)


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


# Public API calls may happen before _ready(), so initialize on first use.
# This checks column counts only; keep width and height fixed during play.
func _initialize_cells_if_needed() -> void:
	if materials.size() == width and burning.size() == width and burn_timers.size() == width:
		return
	_initialize_cells()


# Build a fresh grid with Air, no fire, and zero elapsed burn time.
# Create a separate array for each column so cells do not share column data.
func _initialize_cells() -> void:
	materials.clear()
	burning.clear()
	burn_timers.clear()
	for x in width:
		var material_column: Array = []
		var burning_column: Array = []
		var timer_column: Array = []
		for y in height:
			material_column.append(Materials.AIR)
			burning_column.append(false)
			timer_column.append(0.0)
		materials.append(material_column)
		burning.append(burning_column)
		burn_timers.append(timer_column)
