## Moving-platform contact + extreme 2D projectile sweeps, actual layer-1 shapes.
extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures.append(label);push_error("FAIL: " + label)
func frames(n: int) -> void:
	for _i in n: await physics_frame
func body(parent: Node, name: String, pos: Vector2, extents: Vector2, one_way := false) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = name
	b.position = pos
	b.collision_layer = 1
	b.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = extents
	shape.shape = rect
	shape.one_way_collision = one_way
	b.add_child(shape)
	parent.add_child(b)
	return b
func capture(label: String) -> void:
	var output := OS.get_environment("CAPTURE_CRUSH_SPEED")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	RenderingServer.force_draw(false)
	var err: Error = root.get_texture().get_image().save_png(output + "_" + label + ".png")
	check(err == OK, "captured real moving platform and book: " + label)


func launch(book: GameplayBurnableProp, at: Vector2, motion: Vector2) -> void:
	book._reset_resting()
	book.carried_by = null
	book.global_position = at
	book.flight_velocity = motion
	book.flying = true

func _run() -> void:
	var game := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await frames(65)
	var room := game.get_node("GameplayMSD") as Node2D
	var book := room.get_node("Books/FloorBooks") as GameplayBurnableProp
	var player := room.get_node("Player1") as GameplayPlayer
	var platform := body(room,"SlideTestPlatform", Vector2(265,397), Vector2(140,12), true)
	var wall := body(room,"CrushTestWall", Vector2(385,340), Vector2(12,180))
	if not OS.get_environment("CAPTURE_CRUSH_SPEED").is_empty():
		var outline := Polygon2D.new()
		outline.color = Color("c7555b", 0.83)
		outline.polygon = PackedVector2Array([Vector2(-6,-90),Vector2(6,-90),Vector2(6,90),Vector2(-6,90)])
		outline.z_index = 11
		wall.add_child(outline)
	launch(book,Vector2(310,330),Vector2.ZERO)
	await frames(80)
	check(not book.flying and absf(book.global_position.y - 378.0) < 3.0,"book settles on moving-platform test body")
	var before_x := book.global_position.x
	platform.global_position.x += 105.0
	await frames(3)
	check(book.global_position.x > before_x + 1.0, "book follows moving support until it reaches the wall")
	check(book.global_position.x <= 365.0, "moving platform cannot embed supported book in solid world wall")
	await capture("platform_wall")
	# Player uses Godot CharacterBody2D physics; check physical contact after
	# a platform translation and its built-in floor-motion recovery.
	platform.global_position = Vector2(265,397)
	player.global_position = Vector2(315,370)
	player.velocity = Vector2.ZERO
	player.motor.reset()
	await frames(7)
	check(player.is_on_floor(),"player stands on one-way moving platform")
	for _i in 45:
		platform.global_position.x += 1.35
		await frames(1)
	check(player.global_position.x <= 362.0, "moving platform does not push player into stationary wall")
	check(not is_nan(player.global_position.x) and not is_nan(player.global_position.y),"moving platform never destabilizes CharacterBody2D state")
	# Raise a supported player towards a solid ceiling. The 32x64 capsule
	# must not phase through even if the platform eventually leaves too
	# little vertical room to fit the entire player.
	var roof_for_player := body(room, "PlayerRoof", Vector2(275, 286), Vector2(140, 16))
	platform.global_position = Vector2(265, 397)
	player.global_position = Vector2(278, 365)
	player.velocity = Vector2.ZERO
	player.motor.reset()
	await frames(18)
	check(player.is_on_floor(),"player is grounded before upward crush test")
	for _tick in 34:
		platform.global_position.y -= 1.8
		await frames(1)
	var collider_player: CollisionShape2D = player.get_node("CollisionShape2D")
	var top: float = player.global_position.y + collider_player.position.y - (collider_player.shape as RectangleShape2D).size.y * 0.5
	var ceiling_bottom: float = roof_for_player.global_position.y + 8.0
	print("CRUSH_PLAYER top=",top," roof_bottom=",ceiling_bottom," grounded=",player.is_on_floor()," position=",player.global_position)
	check(top >= ceiling_bottom - 1.0, "rising platform does not force player collision body through solid ceiling")
	check(player.global_position.x > 20.0 and player.global_position.x < 940.0,"crushed player remains within world bounds")
	roof_for_player.queue_free()
	platform.global_position = Vector2(265, 397)
	await frames(4)
	# Extreme diagonal: start-height horizontal ray passes OVER the obstacle,
	# while the endpoint travels through it lower down in a single tick.
	wall.global_position = Vector2(350,330)
	await frames(2)  # allow PhysicsServer2D to sync the wall's new transform
	var high_start := Vector2(260,280)
	launch(book,high_start,Vector2(12000,4000))
	await frames(1)
	check(book.global_position.x <= 336.0, "12k px/s diagonal book cannot tunnel through a thin wall")
	await capture("diagonal_12000")
	# A ceiling is not a one-way platform and must stop ultra-fast upward motion.
	var roof := body(room,"RoofTest",Vector2(610,175),Vector2(120,8))
	wall.global_position = Vector2(350,330)
	launch(book,Vector2(610,263),Vector2(0,-16000))
	await frames(1)
	check(book.global_position.y >= 190.0,"16k px/s upward book cannot tunnel through solid ceiling")
	# Full horizontal speed above the normal 340px/s throw setting.
	var thin_wall := body(room,"UltraThinWall",Vector2(720,300),Vector2(4,240))
	launch(book,Vector2(425,300),Vector2(24000,0))
	await frames(1)
	check(book.global_position.x <= 708.0,"24k px/s sideways book stops before a 4px thin wall")
	# One-way platform should still accept a fast downward landing.
	launch(book,Vector2(245,190),Vector2(0,13000))
	await frames(1)
	check(not book.flying and absf(book.global_position.y-325.0)<3.0,"13k px/s downward book lands on one-way shelf without tunneling")
	# From BELOW the same shelf, even high speeds must pass through.
	launch(book,Vector2(245,384),Vector2(0,-9000))
	await frames(1)
	check(book.flying and book.global_position.y < 322.0,"9k px/s upward flight passes through one-way shelf")
	game.queue_free()
	print("CRUSH_SPEED_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
