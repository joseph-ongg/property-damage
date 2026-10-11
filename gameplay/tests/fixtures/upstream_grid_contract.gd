## 来源：Ethan / Miao-Zinan，origin/ethan/burn-box-grid @ 46c3df2。
## 中文：仅用于测试他的公开 API 契约，重新写的最小模型，不拷贝/修改 Simulation 原代码。
class_name GameplayUpstreamGridContract
extends Node2D

signal cell_changed(x: int, y: int)
enum Materials { AIR, WOOD, STONE, OIL, ASH, WATER }

@export var width: int = 15
@export var height: int = 9
@export var cell_size: int = 16

var materials: Dictionary = {}
var burning: Dictionary = {}

func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func world_to_cell(position: Vector2) -> Vector2i:
	var local := to_local(position)
	return Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))

func set_cell_material(x: int, y: int, material: Materials) -> void:
	if not in_bounds(x, y): return
	var at := Vector2i(x, y)
	materials[at] = material
	burning.erase(at)
	cell_changed.emit(x, y)

func get_cell_material(x: int, y: int) -> Materials:
	if not in_bounds(x, y): return Materials.AIR
	return materials.get(Vector2i(x, y), Materials.AIR) as Materials

func ignite(x: int, y: int) -> void:
	if not in_bounds(x, y): return
	var material := get_cell_material(x, y)
	if material not in [Materials.WOOD, Materials.OIL]: return
	var at := Vector2i(x, y)
	if burning.has(at): return
	burning[at] = true
	cell_changed.emit(x, y)

func is_burning(x: int, y: int) -> bool:
	return burning.has(Vector2i(x,y))

func extinguish(x: int, y: int) -> void:
	if burning.erase(Vector2i(x,y)):
		cell_changed.emit(x, y)
