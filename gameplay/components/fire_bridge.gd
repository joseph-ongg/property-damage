## Only integration point between Gameplay and a MaterialGrid-compatible simulation.
## Assign a grid NodePath to swap the demo grid for the real Simulation grid.
class_name GameplayFireBridge
extends Node

signal cell_ignited(cell: Vector2i)

@export_node_path("Node2D") var grid_path: NodePath


func grid() -> Node:
	return get_node_or_null(grid_path)


func world_to_cell(world_position: Vector2) -> Vector2i:
	var target := grid()
	if target == null or not target.has_method("world_to_cell"):
		return Vector2i(-1, -1)
	return target.call("world_to_cell", world_position)


func ignite_world(world_position: Vector2) -> bool:
	var target := grid()
	if target == null or not target.has_method("ignite") or not target.has_method("world_to_cell"):
		return false
	var cell := world_to_cell(world_position)
	if target.has_method("in_bounds") and not target.call("in_bounds", cell.x, cell.y):
		return false
	target.call("ignite", cell.x, cell.y)
	cell_ignited.emit(cell)
	return true


func is_burning_world(world_position: Vector2) -> bool:
	var target := grid()
	if target == null or not target.has_method("is_burning") or not target.has_method("world_to_cell"):
		return false
	var cell := world_to_cell(world_position)
	if target.has_method("in_bounds") and not target.call("in_bounds", cell.x, cell.y):
		return false
	return bool(target.call("is_burning", cell.x, cell.y))
