## Actual Gameplay Player/Book physics against the October Platform V2 scene.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
func frames(n: int) -> void:
	for _i in n: await physics_frame
func put(p: GameplayPlayer, at: Vector2) -> void:
	p.global_position = at
	p.velocity = Vector2.ZERO
	p.motor.reset()
	p.platform_drop.reset(p)
func snap(label: String) -> void:
	var prefix: String = OS.get_environment("CAPTURE_PLATFORM_V2")
	if prefix.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw(false)
	var err := root.get_texture().get_image().save_png(prefix + "_" + label + ".png")
	check(err == OK, "real Godot viewport captured: " + label)

func _run() -> void:
	var game := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await frames(56)
	var room: Node2D = game.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var names := ["WindowSill", "ACUpperRim", "BedTop", "GalleryFrameTop", "SmallFrameTop",
		"WallShelfLeft", "WallShelfCenter", "WallShelfRight"]
	var coords := [Vector2(152,207),Vector2(648,323),Vector2(72,393),Vector2(480,92),
		Vector2(746,135),Vector2(382,280),Vector2(540,270),Vector2(846,287)]
	var cells := [9,7,8,10,5,6,7,6]
	var grid: MaterialGrid = room.get_node("MaterialGrid")
	var samples: Dictionary = {}
	for i in names.size():
		var ledge: GameplayOneWayLedge = room.get_node(names[i])
		var shape: CollisionShape2D = ledge.get_node("CollisionShape2D")
		check(ledge.global_position == coords[i] and ledge.span_cells == cells[i], "%s mapped to expected Art position" % names[i])
		check(ledge.collision_layer == 1 and ledge.collision_mask == 0 and shape.one_way_collision, "%s is a true layer-1 one-way platform" % names[i])
		check(is_equal_approx((shape.shape as RectangleShape2D).size.x, float(cells[i]*16)), "%s independent collision span aligns to grid" % names[i])
		if i < 5: check(not ledge.visible_surface and ledge.sprite_texture == null, "%s reuses original Art without drawing over it" % names[i])
		else: check(ledge.sprite_texture != null and ledge.sprite_texture.get_width()==cells[i]*16, "%s uses registered original pixel shelf texture" % names[i])
		var point: Vector2i = grid.world_to_cell(ledge.surface_center())
		samples[names[i]] = {"cell":point,"material":grid.get_cell_material(point.x,point.y)}
	await snap("overview")
	# Under-landing coverage for every new platform, including high picture rims.
	for i in names.size():
		var ledge: GameplayOneWayLedge = room.get_node(names[i])
		put(p1, ledge.global_position + Vector2(0,-100))
		await frames(62)
		var expected := ledge.global_position.y - 26.0
		check(p1.is_on_floor() and absf(p1.global_position.y - expected)<3.0, "P1 actually lands on %s (feet coincide with collision)" % names[i])
	# No shared mutable rectangle across prefab instances.
	var left: GameplayOneWayLedge = room.get_node("WallShelfLeft")
	var right: GameplayOneWayLedge = room.get_node("WallShelfRight")
	left.span_cells=8
	check(left.surface_width()==128.0 and right.surface_width()==96.0,"each prefab instance owns a distinct collision shape")
	left.span_cells=6
	for name: String in names:
		var info: Dictionary=samples[name]
		var cell: Vector2i=info.cell
		check(grid.get_cell_material(cell.x,cell.y)==int(info.material),"%s does not overwrite Ethan/Austin material cells"%name)
	# Actual two-player drop: P1 on window and P2 on AC.
	put(p1,Vector2(160,119))
	put(p2,Vector2(648,240))
	await frames(65)
	check(p1.is_on_floor() and absf(p1.global_position.y-181.0)<3.0,"P1 lands on window sill in real co-op")
	check(p2.is_on_floor() and absf(p2.global_position.y-297.0)<3.0,"P2 lands on AC rim independently")
	await snap("both_landed")
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await frames(2)
	Input.action_release("p1_jump")
	Input.action_release("p1_down")
	await frames(64)
	check(p1.global_position.y>248.0,"Down+Jump drops P1 through sill instead of getting stuck")
	check(p2.is_on_floor() and p2.global_position.y<310.0,"P1's drop-through does not affect P2 on the AC")
	await snap("after_drop")
	# Existing thrown book logic must be able to settle on the new shelf.
	var book: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	book._reset_resting()
	book.carried_by=null
	book.global_position=Vector2(382,206)
	book.flying=true
	book.flight_velocity=Vector2.ZERO
	await frames(74)
	check(not book.flying and absf(book.global_position.y-(280.0-19.0))<3.0,"real thrown book settles atop the new wall shelf")
	check(room.get_node("BookshelfTop").position==Vector2(238,344) and room.get_node("TableTop").position==Vector2(485,411),"existing furniture platforms preserved")
	await snap("book_shelf")
	game.queue_free()
	print("PLATFORM_V2_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
