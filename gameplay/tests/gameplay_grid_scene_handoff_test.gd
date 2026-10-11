## Validate the real MSD scene's grid wiring, not just standalone API calls.
## Also runs against a temporary copy where the scene script is switched to Ethan's grid.
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
	var main: PackedScene = load("res://main.tscn")
	check(main != null, "MSD main scene loads for Simulation handoff")
	if main == null:
		quit(1)
		return
	var instance: Node2D = main.instantiate()
	root.add_child(instance)
	for _i in 5:
		await physics_frame
	var room: Node2D = instance.get_node("GameplayMSD")
	var grid: MaterialGrid = room.get_node("MaterialGrid")
	var bridge: GameplayFireBridge = room.get_node("FireBridge")
	var player1: GameplayPlayer = room.get_node("Player1")
	var player2: GameplayPlayer = room.get_node("Player2")
	check(grid is MaterialGrid and bridge.grid() == grid, "both scripts use the Simulation-compatible grid node")
	check(player1._bridge == bridge and player2._bridge == bridge, "two players use the same bridge instance")
	check(room.get_node("FireVisuals")._grid == grid, "visual effects read the same live grid")
	var wood_target := Vector2(400.0, 472.0)
	var wood_cell := bridge.world_to_cell(wood_target)
	check(grid.get_cell_material(wood_cell.x, wood_cell.y) == MaterialGrid.Materials.WOOD, "scene material seeding reaches the actual active grid")
	var event_cells: Array[Vector2i] = []
	bridge.cell_ignited.connect(func(cell: Vector2i): event_cells.append(cell))
	check(bridge.ignite_world(wood_target), "scene Spark lights wood using the active grid")
	check(grid.is_burning(wood_cell.x, wood_cell.y), "Simulation grid—not the bridge—stores the burning cell")
	check(event_cells.size() == 1 and event_cells[0] == wood_cell, "first ignition reports correct cell exactly once")
	check(bridge.ignite_world(wood_target) and event_cells.size() == 1, "repeat Spark does not report duplicate ignition")
	var stone_target := Vector2(782.0, 326.0)
	var stone_cell := bridge.world_to_cell(stone_target)
	check(grid.get_cell_material(stone_cell.x, stone_cell.y) == MaterialGrid.Materials.STONE, "scene paints nonflammable fridge material")
	check(not bridge.ignite_world(stone_target), "scene rejects sparks on fridge stone")
	instance.queue_free()
	print("GRID_SCENE_HANDOFF_SUMMARY grid_script=", grid.get_script().resource_path if is_instance_valid(grid) else "freed", " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
