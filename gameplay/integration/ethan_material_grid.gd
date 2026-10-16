## Gameplay-only Ethan grid adapter (upstream: ethan/burn-box-grid @ 46c3df2).
## The original storage/ignition algorithm is preserved below for main's
## unimplemented base scaffold. Crucially, our fallback arrays have private
## names, so when Ethan's original material_grid.gd is merged into main, this
## script still parses and delegates to the *real parent's* state/methods.
## Never modify onboarding/ from Gameplay or create two active fire stores.
class_name GameplayEthanMaterialGrid
extends MaterialGrid

var _fallback_materials: Array[Array] = []
var _fallback_burning: Array[Array] = []
var _fallback_burn_timers: Array[Array] = []
var _checked_upstream: bool = false
var _has_upstream_storage: bool = false


func using_upstream_storage() -> bool:
	if not _checked_upstream:
		_checked_upstream = true
		var found: Dictionary = {}
		for property: Dictionary in get_property_list():
			if property.name in ["materials", "burning", "burn_timers"]:
				found[property.name] = true
		_has_upstream_storage = found.size() == 3
	return _has_upstream_storage


func _ready() -> void:
	if using_upstream_storage():
		# Main now contains Ethan's actual implementation. No fallback state is
		# created: all methods below forward to his storage and signals.
		super._ready()
		return
	_initialize_fallback_if_needed()
	$TickTimer.wait_time = tick_rate
	$TickTimer.timeout.connect(_on_tick)
	$TickTimer.start()


func _on_tick() -> void:
	if using_upstream_storage():
		super._on_tick()
	# Ethan 46c3df2 does not implement fire spread yet.


func set_cell_material(x: int, y: int, material_id: Materials) -> void:
	if using_upstream_storage():
		super.set_cell_material(x, y, material_id)
		return
	if not in_bounds(x, y):
		return
	_initialize_fallback_if_needed()
	var material_changed: bool = _fallback_materials[x][y] != material_id
	var burning_changed: bool = _fallback_burning[x][y]
	_fallback_materials[x][y] = material_id
	_fallback_burning[x][y] = false
	_fallback_burn_timers[x][y] = 0.0
	if material_changed or burning_changed:
		cell_changed.emit(x, y)


func get_cell_material(x: int, y: int) -> Materials:
	if using_upstream_storage():
		return super.get_cell_material(x, y)
	if not in_bounds(x, y):
		return Materials.AIR
	_initialize_fallback_if_needed()
	return _fallback_materials[x][y]


func ignite(x: int, y: int) -> void:
	if using_upstream_storage():
		super.ignite(x, y)
		return
	if not in_bounds(x, y):
		return
	_initialize_fallback_if_needed()
	if _fallback_burning[x][y]:
		return
	var cell_material: Materials = get_cell_material(x, y)
	if cell_material != Materials.WOOD and cell_material != Materials.OIL:
		return
	_fallback_burning[x][y] = true
	_fallback_burn_timers[x][y] = 0.0
	cell_changed.emit(x, y)


func is_burning(x: int, y: int) -> bool:
	if using_upstream_storage():
		return super.is_burning(x, y)
	if not in_bounds(x, y):
		return false
	_initialize_fallback_if_needed()
	return _fallback_burning[x][y]


func extinguish(x: int, y: int) -> void:
	if using_upstream_storage():
		super.extinguish(x, y)
		return
	if not in_bounds(x, y):
		return
	_initialize_fallback_if_needed()
	if not _fallback_burning[x][y]:
		return
	_fallback_burning[x][y] = false
	_fallback_burn_timers[x][y] = 0.0
	cell_changed.emit(x, y)


func _initialize_fallback_if_needed() -> void:
	if _fallback_materials.size() == width and _fallback_burning.size() == width and _fallback_burn_timers.size() == width:
		return
	_create_fallback_cells()


func _create_fallback_cells() -> void:
	_fallback_materials.clear()
	_fallback_burning.clear()
	_fallback_burn_timers.clear()
	for x in width:
		var column: Array = []
		var burn_column: Array = []
		var timer_column: Array = []
		for y in height:
			column.append(Materials.AIR)
			burn_column.append(false)
			timer_column.append(0.0)
		_fallback_materials.append(column)
		_fallback_burning.append(burn_column)
		_fallback_burn_timers.append(timer_column)


## Test-only introspection; direct gameplay callers must use the public API.
func cell_burn_timer(x: int, y: int) -> float:
	if not in_bounds(x, y):
		return 0.0
	if using_upstream_storage():
		return float(get("burn_timers")[x][y])
	_initialize_fallback_if_needed()
	return float(_fallback_burn_timers[x][y])
