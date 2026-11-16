class_name GameplayFurnitureFireLayer
extends Node

signal object_damaged(object_id: String, hp_left: float)
signal object_destroyed(object_id: String)

@export var destroy_on_burn: bool = true  # tests may turn this off
@export var default_hp: float = 3.0
@export var damage_per_second: float = 1.0
const FLOOR_ROW := 29  # rows 29-31 are the shared wood floor, never part of an object

var _cells: Dictionary = {}    # Vector2i -> object id
var _objects: Dictionary = {}  # id -> {"cells": Array[Vector2i], "hp": float, "destroyed": bool}
var _grid: MaterialGrid


func _ready() -> void:
	_grid = get_parent() as MaterialGrid
	if _grid == null:
		return
	_paint_rect(_grid, 9, 20, 19, 30, "BOOKSHELF")
	_paint_rect(_grid, 23, 37, 23, 25, "TABLE")
	_paint_rect(_grid, 24, 25, 26, 30, "TABLE")
	_paint_rect(_grid, 35, 36, 26, 30, "TABLE")
	_paint_rect(_grid, 23, 37, 30, 30, "TABLE")
	# Wall shelves: derive cells from the ledge's own bounds (3 rows = 48px art).
	for ledge_name in ["WallShelfLeft", "WallShelfCenter", "WallShelfRight"]:
		var ledge := get_parent().get_parent().get_node_or_null(ledge_name) as GameplayOneWayLedge
		if ledge != null:
			register_ledge(ledge, ledge_name.to_upper())


func register_ledge(ledge: GameplayOneWayLedge, id: String) -> void:
	var b := ledge.world_surface_bounds()
	var a := _grid.world_to_cell(b.position)
	var z := _grid.world_to_cell(b.end + Vector2(0, 36))
	_paint_rect(_grid, a.x, z.x, a.y, z.y, id)


func covers_cell(cell: Vector2i) -> bool:
	return _cells.has(cell)


func furniture_at_cell(cell: Vector2i) -> String:
	return str(_cells.get(cell, ""))


func is_destroyed(id: String) -> bool:
	return _objects.has(id) and _objects[id].destroyed


## Used by the renderer: destroyed objects show their ash instead of hiding.
func is_cell_destroyed(cell: Vector2i) -> bool:
	return is_destroyed(furniture_at_cell(cell))


func object_hp(id: String) -> float:
	return _objects[id].hp if _objects.has(id) else 0.0


func object_cells(id: String) -> Array:
	return _objects[id].cells if _objects.has(id) else []


func _physics_process(delta: float) -> void:
	if not destroy_on_burn or _grid == null:
		return
	for id: String in _objects:
		var obj: Dictionary = _objects[id]
		if obj.destroyed or not _any_burning(obj.cells):
			continue
		obj.hp = maxf(0.0, obj.hp - damage_per_second * delta)
		object_damaged.emit(id, obj.hp)
		if obj.hp <= 0.0:
			_destroy(id)


func _any_burning(cells: Array) -> bool:
	for cell: Vector2i in cells:
		if _grid.is_burning(cell.x, cell.y):
			return true
	return false


func _destroy(id: String) -> void:
	var obj: Dictionary = _objects[id]
	obj.destroyed = true
	# Same physics tick, so every cell becomes ASH together. set_cell_material
	# also clears the burning flag, which extinguishes the object.
	for cell: Vector2i in obj.cells:
		_grid.set_cell_material(cell.x, cell.y, MaterialGrid.Materials.ASH)
	object_destroyed.emit(id)


func _paint_rect(grid: MaterialGrid, x_min: int, x_max: int, y_min: int, y_max: int, id: String) -> void:
	if not _objects.has(id):
		_objects[id] = {"cells": [] as Array[Vector2i], "hp": default_hp, "destroyed": false}
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			if not grid.in_bounds(x, y):
				continue
			grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)  # fuel, even on floor rows
			if y >= FLOOR_ROW:
				continue  # fuel only: not part of the object, can't trigger or be ashed
			var cell := Vector2i(x, y)
			if _cells.has(cell):
				continue
			_cells[cell] = id
			_objects[id].cells.append(cell)
