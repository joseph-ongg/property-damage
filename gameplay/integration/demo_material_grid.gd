## Temporary material storage for the isolated Gameplay scenes only.
## Extends the public MaterialGrid interface without modifying Simulation-owned files.
## Replace this scene script with the final MaterialGrid after Simulation merges.
class_name GameplayDemoMaterialGrid
extends MaterialGrid

var _demo_materials: Array[Array] = []
var _demo_burning: Array[Array] = []


func _ready() -> void:
	_ensure_demo_storage()
	super._ready()


func set_cell_material(x: int, y: int, material_id: Materials) -> void:
	if not in_bounds(x, y):
		return
	_ensure_demo_storage()
	var changed: bool = _demo_materials[x][y] != material_id or _demo_burning[x][y]
	_demo_materials[x][y] = material_id
	_demo_burning[x][y] = false
	if changed:
		cell_changed.emit(x, y)


func get_cell_material(x: int, y: int) -> Materials:
	if not in_bounds(x, y):
		return Materials.AIR
	_ensure_demo_storage()
	return _demo_materials[x][y]


func ignite(x: int, y: int) -> void:
	if not in_bounds(x, y):
		return
	_ensure_demo_storage()
	if _demo_burning[x][y]:
		return
	var material: Materials = _demo_materials[x][y]
	if material != Materials.WOOD and material != Materials.OIL:
		return
	_demo_burning[x][y] = true
	cell_changed.emit(x, y)


func is_burning(x: int, y: int) -> bool:
	if not in_bounds(x, y):
		return false
	_ensure_demo_storage()
	return _demo_burning[x][y]


func extinguish(x: int, y: int) -> void:
	if not in_bounds(x, y):
		return
	_ensure_demo_storage()
	if not _demo_burning[x][y]:
		return
	_demo_burning[x][y] = false
	cell_changed.emit(x, y)


func _ensure_demo_storage() -> void:
	if _demo_materials.size() == width and _demo_burning.size() == width:
		if width == 0 or (_demo_materials[0].size() == height and _demo_burning[0].size() == height):
			return
	_demo_materials.clear()
	_demo_burning.clear()
	for x in width:
		var materials_column: Array = []
		var burning_column: Array = []
		for y in height:
			materials_column.append(Materials.AIR)
			burning_column.append(false)
		_demo_materials.append(materials_column)
		_demo_burning.append(burning_column)
