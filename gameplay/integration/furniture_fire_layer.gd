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

const ITEM_HP := {
	"COMPUTER": 15.0, "AC": 20.0, "FAN": 20.0, "CLOCK": 10.0, "PAINTING": 5.0,
	"BOOKS": 5.0, "TRASHCAN": 10.0, "MICROWAVE": 17.0, "PLUSHIE": 7.0, "PLANT": 10.0,
}

func hp_for(id: String) -> float:
	for prefix: String in ITEM_HP:
		if id.begins_with(prefix):
			return ITEM_HP[prefix]
	return default_hp

func max_hp_for(id: String) -> float:
	return hp_for(id)

func _ready() -> void:
	_grid = get_parent() as MaterialGrid
	if _grid == null:
		return

	var room := _grid.get_parent()
	var pc := room.get_node_or_null("Appliances/ComputerDevice") as GameplayAppliance
	if pc != null:
		register_world_rect(_world_rect(pc, GameplayAppliance.MONITOR_RENDER_RECT), "COMPUTER")
	var fan := room.get_node_or_null("Appliances/FanDevice") as GameplayAppliance
	if fan != null:
		register_world_rect(_world_rect(fan, GameplayAppliance.FAN_RECT), "FAN")

# Baked-in art: cells only, the pixels stay until the art is split out.
	register_world_rect(Rect2(790, 96, 88, 88), "CLOCK")
	register_world_rect(Rect2(402, 88, 152, 110), "PAINTING_LANDSCAPE")
	register_world_rect(Rect2(106, 116, 78, 62), "PAINTING_LEFT")
	register_world_rect(Rect2(706, 126, 78, 62), "PAINTING_RIGHT")

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

	var fridge := room.get_node_or_null("Appliances/FridgeDevice") as GameplayAppliance
	if fridge != null:
		# max_row 29: floor row 29 is where players aim from the ground.
		register_world_rect(_world_rect(fridge, GameplayAppliance.FRIDGE_RENDER_RECT), "FRIDGE", 29)
	var ac := room.get_node_or_null("Appliances/ACDevice") as GameplayAppliance
	if ac != null:
		register_world_rect(_world_rect(ac, GameplayAppliance.AC_RENDER_RECT), "AC")

func _world_rect(node: Node2D, local: Rect2) -> Rect2:
	return Rect2(node.global_position + local.position, local.size)


func register_world_rect(rect: Rect2, id: String, max_row: int = FLOOR_ROW - 1) -> void:
	var a := _grid.world_to_cell(rect.position)
	var z := _grid.world_to_cell(rect.end - Vector2.ONE)
	_paint_rect(_grid, a.x, z.x, a.y, z.y, id, max_row)


func _paint_rect(grid: MaterialGrid, x_min: int, x_max: int, y_min: int, y_max: int, id: String, max_row: int = FLOOR_ROW - 1) -> void:
	if not _objects.has(id):
		_objects[id] = {"cells": [] as Array[Vector2i], "hp": hp_for(id), "destroyed": false}
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			if not grid.in_bounds(x, y):
				continue
			grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)
			if y > max_row:
				continue
			var cell := Vector2i(x, y)
			if not _objects[id].cells.has(cell):
				_objects[id].cells.append(cell)
			if not _cells.has(cell):
				_cells[cell] = id


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

func _cell_shared(cell: Vector2i, id: String) -> bool:
	for other: String in _objects:
		if other != id and not _objects[other].destroyed and _objects[other].cells.has(cell):
			return true
	return false

func _destroy(id: String) -> void:
	var obj: Dictionary = _objects[id]
	obj.destroyed = true
	for cell: Vector2i in obj.cells:
		if not _cell_shared(cell, id):
			_grid.set_cell_material(cell.x, cell.y, MaterialGrid.Materials.ASH)
	object_destroyed.emit(id)
