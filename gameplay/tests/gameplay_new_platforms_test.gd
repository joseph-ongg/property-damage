## Real Godot scene / co-op physics regression for Suwen's new platforms.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func frames(n: int) -> void:
	for _i in n: await physics_frame

func put(p: GameplayPlayer, pos: Vector2) -> void:
	p.global_position = pos
	p.velocity = Vector2.ZERO
	p.motor.reset()
	p.platform_drop.reset(p)

func capture(label: String) -> void:
	var prefix := OS.get_environment("CAPTURE_PLATFORMS")
	if prefix.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw(false)
	var result: Error = root.get_texture().get_image().save_png(prefix + "_" + label + ".png")
	check(result == OK, "Godot actual platform screenshot saved: " + label)

func _run() -> void:
	var game: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await frames(60)
	var room: Node2D = game.get_node("GameplayMSD")
	var names := ["LeftStep", "GalleryStep", "RightStep", "UpperRightStep"]
	var positions := [Vector2(112,416),Vector2(400,288),Vector2(880,416),Vector2(704,256)]
	var ids := [&"living_left_step",&"living_gallery_step",&"living_right_step",&"living_upper_right_step"]
	for i in names.size():
		var ledge: GameplayOneWayLedge = room.get_node(names[i])
		var shape := ledge.get_node("CollisionShape2D") as CollisionShape2D
		check(ledge != null and ledge.platform_id == ids[i] and ledge.global_position == positions[i], "%s remains in Level Design slot with stable id" % names[i])
		check(ledge.collision_layer == 1 and ledge.collision_mask == 0 and shape.one_way_collision, "%s uses only world layer and one-way collision" % names[i])
		check(is_equal_approx((shape.shape as RectangleShape2D).size.x, ledge.surface_width()), "%s collision matches exported grid-cell width" % names[i])
		check(is_equal_approx(fmod(ledge.surface_width(),16.0),0.0), "%s spans whole 16px design cells" % names[i])
		check(is_zero_approx(fmod(ledge.global_position.x, 16.0)) and is_zero_approx(fmod(ledge.global_position.y, 16.0)), "%s anchor aligns to Austin's 16px grid" % names[i])
	var gallery: GameplayOneWayLedge = room.get_node("GalleryStep")
	var left: GameplayOneWayLedge = room.get_node("LeftStep")
	var old_width: float = gallery.surface_width()
	left.span_cells = 8
	check(left.surface_width() == 128.0 and gallery.surface_width() == old_width, "changing one instance width does not resize other platforms")
	left.span_cells = 6
	check(left.world_surface_bounds().size == Vector2(96,12), "grid-ready exposed bounds match actual platform geometry")
	var grid: MaterialGrid = room.get_node("MaterialGrid")
	var target_cell := grid.world_to_cell(gallery.surface_center())
	var prior_material: int = grid.get_cell_material(target_cell.x,target_cell.y)
	gallery.material_tag = &"stone"
	check(grid.get_cell_material(target_cell.x,target_cell.y) == prior_material, "Art/Design material hint never overwrites Ethan's authoritative grid")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	# Both players jump from the floor and land on the new lower steps.
	put(p1, Vector2(112,478))
	put(p2, Vector2(887,478))
	await frames(5)
	Input.action_press("p1_jump")
	Input.action_press("p2_jump")
	await frames(2)
	Input.action_release("p1_jump")
	Input.action_release("p2_jump")
	await frames(67)
	check(p1.is_on_floor() and absf(p1.global_position.y - (416-26)) < 3.0, "P1 jumps from floor and lands on new LeftStep")
	check(p2.is_on_floor() and absf(p2.global_position.y - (416-26)) < 3.0, "P2 jumps from floor and lands on new RightStep")
	check(p1.collision_mask == 1 and p2.collision_mask == 1, "both players keep world-only collision masks")
	await capture("landed")
	# Down + Jump only passes a one-way ledge, not the solid world floor.
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await frames(2)
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	await frames(55)
	check(p1.is_on_floor() and p1.global_position.y > 455.0, "P1 drops through added ledge and lands on solid floor")
	check(p2.is_on_floor() and p2.global_position.y < 425.0, "P1 drop-through does not disturb P2 on other ledge")
	await capture("drop")
	# The physical bookshelf route to the upper gallery remains traversable.
	put(p1,Vector2(400,212))
	await frames(48)
	check(p1.is_on_floor() and absf(p1.global_position.y - (288-26)) < 3.0, "P1 lands on new GalleryStep without hitting fake blocking walls")
	# Test a real thrown book settling on the additional platform.
	var book: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	book._reset_resting()
	book.carried_by = null
	book.global_position = Vector2(394,185)
	book.flying = true
	book.flight_velocity = Vector2.ZERO
	await frames(65)
	check(not book.flying and absf(book.global_position.y-(288-6-13))<3.0, "book lands and rests on the new platform using existing physics")
	# Restart and platform state do not depend on scene-only input remapping.
	check(p1.collision_mask == 1 and p2.collision_mask == 1, "existing player collisions stay unchanged")
	game.queue_free()
	print("NEW_PLATFORMS_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
