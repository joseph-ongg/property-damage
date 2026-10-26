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
	var menu: Control = load("res://gameplay/level_select.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	(menu.get_node("GardenButton") as Button).pressed.emit()
	for _i in 65:
		await physics_frame
	var garden: Node2D = current_scene.get_node_or_null("GameplayMSD")
	check(garden != null, "Garden selection opens a playable arena")
	if garden == null:
		quit(1)
		return
	check(bool(garden.get("garden_level")), "selected arena is the garden variant")
	check(garden.get_node_or_null("GardenVisuals") != null, "garden artwork is present")
	check(garden.get_node("Player1") != null and garden.get_node("Player2") != null, "garden has both players")
	check(garden.get_node("Player1").is_on_floor() and garden.get_node("Player2").is_on_floor(), "both garden players spawn on the ground")
	var grid: MaterialGrid = garden.get_node("MaterialGrid")
	var bridge: GameplayFireBridge = garden.get_node("FireBridge")
	check(bridge.grid() == grid, "garden Spark uses its active MaterialGrid")
	for target in [Vector2(100, 260), Vector2(299, 459), Vector2(750, 459), Vector2(785, 320), Vector2(620, 24)]:
		var cell: Vector2i = bridge.world_to_cell(target)
		check(grid.get_cell_material(cell.x, cell.y) == MaterialGrid.Materials.WOOD, "%s is seeded as burnable wood" % str(target))
		check(bridge.ignite_world(target) and grid.is_burning(cell.x, cell.y), "%s ignites through the shared grid" % str(target))
	var empty_cell: Vector2i = bridge.world_to_cell(Vector2(395, 202))
	check(grid.get_cell_material(empty_cell.x, empty_cell.y) == MaterialGrid.Materials.AIR, "open garden air stays unburnable")
	check(not bridge.ignite_world(Vector2(395, 202)), "sparks in open air are rejected")
	print("GARDEN_LEVEL_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
