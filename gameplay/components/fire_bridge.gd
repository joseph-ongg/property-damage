## Only integration point between Gameplay and a MaterialGrid-compatible simulation.
## Assign a grid NodePath to swap the demo grid for the real Simulation grid.
## 来源：Ethan（Miao-Zinan），origin/ethan/burn-box-grid @ 46c3df2。
## EN: Source: Ethan (Miao-Zinan), remote ethan/burn-box-grid, commit 46c3df2.
## 中文：他的 ignite() 不返回成功标记；必须再读 is_burning() 才能判断是否真的点着。
## EN: The upstream ignite() returns no success flag; read is_burning() to confirm ignition.
## 保持 Simulation 原文件不变，只修改 Gameplay 适配层。
## EN: Leave the original Simulation files unchanged; adapt only the Gameplay bridge.
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
	# 中文：木头和油可以燃烧，空气/石头/水不行。不能把调用成功当成点火成功。
	# EN: Wood and oil burn, but air, stone and water do not; a method call alone is not success.
	# 上游 MaterialGrid.ignite() 返回 void；用调用前后状态识别新点火。
	# EN: Upstream MaterialGrid.ignite() returns void; compare the states before and after.
	var previously_burning := false
	if target.has_method("is_burning"):
		previously_burning = bool(target.call("is_burning", cell.x, cell.y))
	target.call("ignite", cell.x, cell.y)
	if not target.has_method("is_burning"):
		return false  # 无法验证，不谎报成功 / EN: Do not report success when ignition cannot be verified.
	var burning_now := bool(target.call("is_burning", cell.x, cell.y))
	if burning_now and not previously_burning:
		cell_ignited.emit(cell)
	return burning_now


func is_burning_world(world_position: Vector2) -> bool:
	var target := grid()
	if target == null or not target.has_method("is_burning") or not target.has_method("world_to_cell"):
		return false
	var cell := world_to_cell(world_position)
	if target.has_method("in_bounds") and not target.call("in_bounds", cell.x, cell.y):
		return false
	return bool(target.call("is_burning", cell.x, cell.y))
