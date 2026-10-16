## Actual Art Team sprites must line up with collision platforms and
## material-grid target cells after visual material replacement.
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
	var scene: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for _i in 65:
		await physics_frame
	var room: Node2D = scene.get_node("GameplayMSD")
	var grid: MaterialGrid = room.get_node("MaterialGrid")
	var bridge: GameplayFireBridge = room.get_node("FireBridge")
	var fridge: GameplayAppliance = room.get_node("Appliances/FridgeDevice")
	var ac: GameplayAppliance = room.get_node("Appliances/ACDevice")
	var monitor: GameplayAppliance = room.get_node("Appliances/ComputerDevice")
	var platform: StaticBody2D = room.get_node("FridgeTop")
	var platform_shape: CollisionShape2D = platform.get_node("CollisionShape2D")
	var fridge_rect: Rect2 = GameplayAppliance.FRIDGE_RENDER_RECT
	var ac_rect: Rect2 = GameplayAppliance.AC_RENDER_RECT
	var monitor_rect: Rect2 = GameplayAppliance.MONITOR_RENDER_RECT
	var fridge_texture: Texture2D = GameplayAppliance.TEAM_FRIDGE
	var ac_texture: Texture2D = GameplayAppliance.TEAM_AC
	var monitor_texture: Texture2D = GameplayAppliance.TEAM_MONITOR
	var fridge_top := fridge.global_position.y + fridge_rect.position.y
	var fridge_bottom := fridge_top + fridge_rect.size.y
	var platform_top := platform.global_position.y - (platform_shape.shape as RectangleShape2D).size.y * 0.5
	check(is_equal_approx(fridge_top, platform_top), "fridge image and physical platform begin at the same height")
	check(is_equal_approx(fridge_bottom, 498.0), "fridge artwork ends at the real floor surface")
	check(fridge_rect.size.x <= (platform_shape.shape as RectangleShape2D).size.x and (platform_shape.shape as RectangleShape2D).size.x <= fridge_rect.size.x + 8.0, "fridge platform width matches the Art Team image footprint")
	check(absf(fridge_rect.size.x / fridge_rect.size.y - float(fridge_texture.get_width()) / float(fridge_texture.get_height())) < 0.02, "fridge art preserves source aspect ratio")
	check(absf(ac_rect.size.x / ac_rect.size.y - float(ac_texture.get_width()) / float(ac_texture.get_height())) < 0.10, "air conditioner retains the Art Team's wide silhouette")
	check(absf(monitor_rect.size.x / monitor_rect.size.y - float(monitor_texture.get_width()) / float(monitor_texture.get_height())) < 0.10, "monitor texture retains original proportions")
	check(monitor.global_position.y + monitor_rect.end.y >= 410.0, "monitor stand visually meets the desk")
	check(ac.global_position.y + ac_rect.position.y < 330.0 and ac.global_position.y + ac_rect.end.y < 365.0, "AC visually hangs on wall, above the desk")
	for node_path in ["RoomVisuals", "Appliances", "Projectiles", "FireVisuals"]:
		var canvas: CanvasItem = room.get_node(node_path)
		check(canvas.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, node_path + " uses crisp pixel-art rendering")

	var shelf_spark := Vector2(200, 318)
	var shelf_cell := bridge.world_to_cell(shelf_spark)
	check(grid.get_cell_material(shelf_cell.x, shelf_cell.y) == MaterialGrid.Materials.WOOD, "sparks at shelf standing height hit WOOD, not AIR")
	check(bridge.ignite_world(shelf_spark), "standing on bookshelf can ignite nearby bookshelf material")
	var fridge_top_target := Vector2(782, 326)
	check(not bridge.ignite_world(fridge_top_target), "fridge collision-level material is nonflammable")
	var fridge_base := Vector2(780, 478)
	var fridge_cell := bridge.world_to_cell(fridge_base)
	check(grid.get_cell_material(fridge_cell.x, fridge_cell.y) == MaterialGrid.Materials.STONE, "fridge footprint cannot catch fire through floor WOOD material")
	check(not bridge.ignite_world(fridge_base), "Spark rejects visually false fridge-base ignition")
	check(bridge.ignite_world(Vector2(850, 478)), "wood floor immediately outside fridge still accepts Spark")
	check(bridge.grid() == grid and room.get_node("FireVisuals")._grid == grid, "artwork replacement does not create duplicate Simulation storage")

	check(fridge.can_interact(room.get_node("Player2")) == false, "fridge interaction still checks real player proximity")
	room.get_node("Player2").global_position = Vector2(795, 478)
	for _i in 3:
		await physics_frame
	check(fridge.can_interact(room.get_node("Player2")), "resized fridge is still interactable from floor")
	check(fridge.interact(room.get_node("Player2")) and fridge.switched_on, "fridge open state still works with new material")
	check(fridge.interact(room.get_node("Player2")) and not fridge.switched_on, "fridge closes without changing physics")

	scene.queue_free()
	print("ART_SCENE_ALIGNMENT_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
