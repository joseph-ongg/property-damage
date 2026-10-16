## End-to-end MSD acceptance: two players use real InputMap actions in the same game.
## Exercise cooperative/opposing inputs, platforms, Spark, books, appliances and UI.
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


func frames(n: int) -> void:
	for _i in n:
		await physics_frame


func tap(action: StringName, hold_frames: int = 3) -> void:
	Input.action_press(action)
	await frames(hold_frames)
	Input.action_release(action)


func reposition(player: GameplayPlayer, point: Vector2) -> void:
	player.global_position = point
	player.velocity = Vector2.ZERO
	player.motor.reset()
	player.platform_drop.reset(player)


func _run() -> void:
	var pack: PackedScene = load("res://gameplay/playtest_main.tscn")
	check(pack != null, "main scene can be loaded")
	if pack == null:
		quit(1)
		return
	var main: Node2D = pack.instantiate()
	root.add_child(main)
	await frames(65)
	var room: Node2D = main.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var bridge: GameplayFireBridge = room.get_node("FireBridge")
	var grid: MaterialGrid = room.get_node("MaterialGrid")
	var fan: GameplayAppliance = room.get_node("Appliances/FanDevice")
	var fridge: GameplayAppliance = room.get_node("Appliances/FridgeDevice")
	var ac: GameplayAppliance = room.get_node("Appliances/ACDevice")
	var book: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	var indicators: Node2D = room.get_node("PlayerConditions")
	var hints: Node2D = room.get_node("InteractionHints")
	check(p1.is_on_floor() and p2.is_on_floor(), "both players spawn on solid floor")
	check(p1.collision_layer == 2 and p2.collision_layer == 2 and p1.collision_mask == 1 and p2.collision_mask == 1, "both player collision layers follow Simulation contract")
	check(bridge.grid() == grid, "both players share the installed grid through one bridge")

	# Simultaneous P1/P2 directions on the same keyboard.
	var left_start := p1.global_position.x
	var right_start := p2.global_position.x
	Input.action_press("p1_right")
	Input.action_press("p2_left")
	await frames(14)
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	check(p1.global_position.x > left_start + 25.0 and p2.global_position.x < right_start - 25.0, "simultaneous opposite directions move both players")
	check(p1.facing == 1 and p2.facing == -1, "each player's facing stays independent")
	await frames(30)
	check(p1.velocity.x == 0.0 and p2.velocity.x == 0.0, "players brake after releasing ground movement")

	# Simultaneous first and second jumps.
	reposition(p1, Vector2(110, 478))
	reposition(p2, Vector2(835, 478))
	await frames(5)
	Input.action_press("p1_jump")
	Input.action_press("p2_jump")
	await frames(3)
	Input.action_release("p1_jump")
	Input.action_release("p2_jump")
	check(p1.velocity.y < -100.0 and p2.velocity.y < -100.0, "two simultaneous first jumps launch independently")
	await frames(8)
	Input.action_press("p1_jump")
	Input.action_press("p2_jump")
	await frames(3)
	Input.action_release("p1_jump")
	Input.action_release("p2_jump")
	check(p1.motor.jumps_remaining() == 0 and p2.motor.jumps_remaining() == 0, "simultaneous double jumps consume both charges")
	await frames(90)
	check(p1.is_on_floor() and p2.is_on_floor(), "both players recover after double jump")
	check(p1.motor.jumps_remaining() == 2 and p2.motor.jumps_remaining() == 2, "jump charges reset separately upon landing")

	# Real directional sparks target the cell in front, not beneath or behind.
	# P2 must cast from the wood floor *outside* the fridge's STONE
	# footprint. Former x=800 aimed inside the fridge and masked this bug.
	reposition(p1, Vector2(142, 478))
	reposition(p2, Vector2(884, 478))
	p1.facing = 1
	p2.facing = -1
	await frames(3)
	var p1_target := p1.global_position + Vector2(p1.spark.reach, 0)
	var p2_target := p2.global_position + Vector2(-p2.spark.reach, 0)
	var p1_cell := bridge.world_to_cell(p1_target)
	var p2_cell := bridge.world_to_cell(p2_target)
	check(grid.get_cell_material(p1_cell.x, p1_cell.y) == MaterialGrid.Materials.WOOD, "P1 targets flammable floor material")
	check(grid.get_cell_material(p2_cell.x, p2_cell.y) == MaterialGrid.Materials.WOOD, "P2 targets flammable floor material")
	Input.action_press("p1_spark")
	Input.action_press("p2_spark")
	await frames(3)
	Input.action_release("p1_spark")
	Input.action_release("p2_spark")
	check(grid.is_burning(p1_cell.x, p1_cell.y) and grid.is_burning(p2_cell.x, p2_cell.y), "simultaneous F and Enter ignite both facing cells")
	check(room.sparks_p1 == 1 and room.sparks_p2 == 1, "both Spark actions report success independently")

	# Both players drop through the same one-way table without getting stuck.
	reposition(p1, Vector2(435, 360))
	reposition(p2, Vector2(530, 360))
	await frames(27)
	check(p1.is_on_floor() and p2.is_on_floor(), "both players land on the same one-way table")
	Input.action_press("p1_down")
	Input.action_press("p2_down")
	Input.action_press("p1_jump")
	Input.action_press("p2_jump")
	await frames(3)
	Input.action_release("p1_jump")
	Input.action_release("p2_jump")
	Input.action_release("p1_down")
	Input.action_release("p2_down")
	check(p1.platform_drop.is_dropping() and p2.platform_drop.is_dropping(), "both Down+Jump actions initiate separate drops")
	await frames(75)
	check(p1.is_on_floor() and p2.is_on_floor() and not p1.platform_drop.is_dropping() and not p2.platform_drop.is_dropping(), "both drops safely finish on solid floor")

	# P1's E and P2's Shift must act on different items concurrently.
	reposition(p1, Vector2(310, 478))
	reposition(p2, Vector2(795, 478))
	await frames(5)
	check(room.get_interaction_offer(p1).get("target") == book, "P1's pickup prompt selects floor books")
	check(room.get_interaction_offer(p2).get("target") == fridge, "P2's interaction selects fridge")
	Input.action_press("p1_interact")
	Input.action_press("p2_interact")
	await frames(3)
	Input.action_release("p1_interact")
	Input.action_release("p2_interact")
	check(book.carried_by == p1 and room.held_books.has(1), "P1 E picks up the book")
	check(fridge.switched_on, "P2 Shift opens the fridge at the same time")
	check(hints.hint_for(p1).contains("THROW"), "P1 prompt switches to throw")
	await tap("p1_interact")
	check(book.carried_by == null and book.flying and not room.held_books.has(1), "P1 E throws without affecting P2 fridge")
	await tap("p2_interact")
	check(not fridge.switched_on, "P2 Shift can close fridge after P1 throws")
	await frames(110)
	check(not book.flying and book.global_position.y <= 485.1, "thrown book settles in world boundaries")

	# AC and fan effects must not leak between player instances.
	reposition(p1, Vector2(413, 478))
	reposition(p2, Vector2(647, 478))
	await frames(5)
	check(room.get_interaction_offer(p1).get("target") == fan, "P1 can operate tabletop fan from ground")
	check(room.get_interaction_offer(p2).get("target") == ac, "P2 can operate wall-mounted AC from ground")
	Input.action_press("p1_interact")
	Input.action_press("p2_interact")
	await frames(3)
	Input.action_release("p1_interact")
	Input.action_release("p2_interact")
	check(fan.switched_on and ac.switched_on, "simultaneous appliance interactions activate both devices")
	check(indicators.get_condition(p1) == "WIND" and indicators.get_condition(p2) == "SLOW", "players receive independent WIND and SLOW statuses")
	await frames(10)
	check(p1.motor.environment_acceleration_x < -100 and p2.motor.speed_scale < 0.5, "fan and AC apply independent real movement effects")
	check(p1.motor.speed_scale == 1.0 and is_zero_approx(p2.motor.environment_acceleration_x), "effects do not leak to distant player")

	# Both ranged spells can hit distinct props in the same physics sequence.
	fan.switched_on = false
	ac.switched_on = false
	var tabletop_book: GameplayBurnableProp = room.get_node("Books/TableBooks")
	var pc: GameplayAppliance = room.get_node("Appliances/ComputerDevice")
	check(not tabletop_book.scorched and not pc.charred, "ranged-attack targets begin intact")
	reposition(p1, Vector2(395, 405))
	reposition(p2, Vector2(620, 384))
	p1.facing = 1
	p2.facing = -1
	await frames(4)
	Input.action_press("p1_attack")
	Input.action_press("p2_attack")
	await frames(3)
	Input.action_release("p1_attack")
	Input.action_release("p2_attack")
	await frames(26)
	check(tabletop_book.scorched, "P1 G spell reaches and scorches tabletop books")
	check(pc.charred, "P2 period spell reaches and shorts the computer")
	check(room.sparks_p1 == 1 and room.sparks_p2 == 1, "ranged spells never counterfeit Simulation Spark counts")
	check(room.get_node("Projectiles").get_child_count() == 0, "hit projectiles are cleaned up promptly")

	# Wall collisions must still contain both players after physics interactions.
	fan.switched_on = false
	ac.switched_on = false
	reposition(p1, Vector2(25, 478))
	reposition(p2, Vector2(935, 478))
	await frames(5)
	Input.action_press("p1_left")
	Input.action_press("p2_right")
	await frames(75)
	Input.action_release("p1_left")
	Input.action_release("p2_right")
	check(p1.global_position.x >= 10 and p2.global_position.x <= 950, "both outer walls block outward movement")
	check(p1.global_position.y < 510 and p2.global_position.y < 510, "solid floor still bounds both players")

	# Keep running to expose stale statuses, stuck drops and orphaned projectiles.
	await frames(260)
	check(not p1.platform_drop.is_dropping() and not p2.platform_drop.is_dropping(), "no stuck drop exceptions after long idle")
	check(room.get_node("Projectiles").get_child_count() == 0, "no projectiles linger after long idle")
	check(not paused, "normal long play never pauses spontaneously")

	for action in ["p1_left", "p1_right", "p1_jump", "p1_down", "p1_spark", "p1_interact", "p1_attack", "p2_left", "p2_right", "p2_jump", "p2_down", "p2_spark", "p2_interact", "p2_attack"]:
		Input.action_release(action)
	main.queue_free()
	print("FULL_FLOW_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
