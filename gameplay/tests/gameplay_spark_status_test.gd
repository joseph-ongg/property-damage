## MSD integration regression: a failed Spark does not imply the fire grid is missing.
## Verify missing-grid, out-of-bounds, and nonflammable-material feedback separately.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _run() -> void:
	var main: PackedScene = load("res://gameplay/playtest_main.tscn")
	check(main != null, "default MSD main scene can be loaded")
	if main == null:
		quit(1)
		return
	var instance: Node2D = main.instantiate()
	root.add_child(instance)
	await physics_frame
	await physics_frame
	var arena: Node2D = instance.get_node("GameplayMSD")
	var bridge: GameplayFireBridge = arena.get_node("FireBridge")
	var grid: MaterialGrid = arena.get_node("MaterialGrid")
	var status: Label = arena.get_node("HUD/SparkStatus")
	var original_grid_path: NodePath = bridge.grid_path
	var stone_target := Vector2(782.0, 326.0)
	var stone_cell := grid.world_to_cell(stone_target)
	check(grid.get_cell_material(stone_cell.x, stone_cell.y) == MaterialGrid.Materials.STONE, "fridge material is intentionally nonflammable")
	check(not bridge.ignite_world(stone_target), "spark cannot ignite a stone cell")
	arena._on_sparked(1, stone_target, false)
	check(status.text.contains("NOT IGNITED") and not status.text.contains("NOT READY"), "nonflammable spark reports rejected ignition, not a missing grid")

	var wood_target := Vector2(400.0, 472.0)
	var wood_cell := grid.world_to_cell(wood_target)
	check(grid.get_cell_material(wood_cell.x, wood_cell.y) == MaterialGrid.Materials.WOOD, "floor material is combustible")
	check(bridge.ignite_world(wood_target), "first spark ignites combustible wood")
	arena._on_sparked(1, wood_target, true)
	check(status.text.contains("CELL") and status.text.contains("BURNING"), "spark reports successful burning state")
	check(bridge.ignite_world(wood_target), "repeated spark can target an already burning cell")
	arena._on_sparked(1, wood_target, true)
	check(status.text.contains("BURNING") and not status.text.contains("IGNITED"), "repeated spark does not claim a new ignition")

	var outside_target := Vector2(-48, -48)
	check(not bridge.ignite_world(outside_target), "out-of-bounds ignition is safely rejected")
	arena._on_sparked(2, outside_target, false)
	check(status.text.contains("OUTSIDE FIRE GRID"), "out-of-bounds spark reports an invalid target")

	bridge.grid_path = NodePath("../MissingSimulationGrid")
	check(not bridge.ignite_world(stone_target), "missing Simulation grid fails safely")
	arena._on_sparked(1, stone_target, false)
	check(status.text.contains("FIRE GRID NOT READY"), "missing Simulation grid reports an integration issue")
	bridge.grid_path = original_grid_path
	check(bridge.grid() == grid, "bridge reconnects to the original Simulation grid")

	instance.queue_free()
	print("SPARK_STATUS_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
