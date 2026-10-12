## Property Damage MSD deliverables, not the optional Moonlit Ruins quest.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)


func frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _run() -> void:
	var main: PackedScene = load("res://gameplay/playtest_main.tscn")
	check(main != null, "default main scene loads")
	if main == null:
		quit(1)
		return
	var instance := main.instantiate()
	root.add_child(instance)
	await frames(6)
	var arena := instance.get_node("GameplayMSD")
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	var grid: Node2D = arena.get_node("MaterialGrid")
	var bridge: GameplayFireBridge = arena.get_node("FireBridge")
	check(grid is GameplayDemoMaterialGrid and grid.get_script().resource_path == "res://gameplay/integration/demo_material_grid.gd", "default demo uses isolated Gameplay storage without replacing Simulation files")
	check(arena.has_node("FireVisuals") and not arena.has_node("DemoFireGrid"), "visual overlay no longer owns a duplicate burning store")
	check(arena.get_node("HUD/Title").text == "PROPERTY DAMAGE", "official title replaces invented quest name")
	check(arena.get_node("HUD/Subtitle").text.contains("PROTOTYPE"), "demo explicitly labeled prototype")
	var playtest_hud: CanvasLayer = arena.get_node("HUD")
	check(playtest_hud.has_node("SparkStatus") and playtest_hud.has_node("Controls") and playtest_hud.has_node("ControlsP2") and playtest_hud.has_node("SystemHint") and not playtest_hud.has_node("Quest") and not playtest_hud.has_node("Score"), "playtest HUD prioritizes separate P1/P2 controls and real Simulation feedback, not invented objectives")
	check(not arena.has_node("Braziers") and not arena.has_node("Shards") and not arena.has_node("VictoryOverlay"), "unapproved quest and win conditions absent")
	check(p1.collision_layer == 2 and p1.collision_mask == 1 and p2.collision_mask == 1, "two player bodies collide only with world")
	check(not p1.dash_enabled and not p2.dash_enabled, "extra dash disabled in official MSD")
	check(InputMap.has_action("p1_jump") and InputMap.has_action("p2_jump") and InputMap.has_action("p2_spark"), "both key control sets registered")
	for name in ["BookshelfTop", "TableTop", "FridgeTop"]:
		var static_body: StaticBody2D = arena.get_node(name)
		check(static_body.collision_layer == 1 and static_body.get_node("CollisionShape2D").one_way_collision, name + " is a one-way world platform")
	for name in ["Floor", "LeftWall", "RightWall"]:
		var boundary: StaticBody2D = arena.get_node(name)
		check(boundary.collision_layer == 1 and not boundary.get_node("CollisionShape2D").one_way_collision, name + " is solid world geometry")
	await frames(65)
	check(p1.is_on_floor() and p2.is_on_floor(), "both players safely land on the floor")
	var x1 := p1.global_position.x
	var x2 := p2.global_position.x
	Input.action_press("p1_right")
	Input.action_press("p2_left")
	await frames(18)
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	check(p1.global_position.x > x1 + 20 and p2.global_position.x < x2 - 20, "two players move independently toward each other")
	# 上游真实 Grid 的 cell_size=16，玩家在空中会保留惯性；必须验证实际施法坐标。
	# The real 16px MaterialGrid requires validating the exact target emitted mid-movement.
	var p1_targets: Array[Vector2] = []
	var p2_targets: Array[Vector2] = []
	p1.sparked.connect(func(_index: int, pos: Vector2, _accepted: bool): p1_targets.append(pos))
	p2.sparked.connect(func(_index: int, pos: Vector2, _accepted: bool): p2_targets.append(pos))
	Input.action_press("p1_spark")
	await frames(3)
	Input.action_release("p1_spark")
	check(p1_targets.size() == 1, "P1 emits actual spell target once")
	var target: Vector2 = p1_targets[0]
	var cell: Vector2i = grid.call("world_to_cell", target)
	check(grid.call("is_burning", cell.x, cell.y), "P1 spark ignites the actual target cell")
	check(arena.sparks_p1 == 1 and arena.sparks_p2 == 0, "only correct player's ignition count increments")
	check(bridge.is_burning_world(target), "MaterialGrid fire bridge reads real burning cell")
	Input.action_press("p2_spark")
	await frames(3)
	Input.action_release("p2_spark")
	check(p2_targets.size() == 1, "P2 emits actual spell target once")
	target = p2_targets[0]
	cell = grid.call("world_to_cell", target)
	check(grid.call("is_burning", cell.x, cell.y), "P2 spark ignites the actual target cell")
	check(arena.sparks_p2 == 1, "P2 ignition recorded")
	# Existing pause control retained with much less screen UI.
	var pause: CanvasLayer = arena.get_node("PauseOverlay")
	pause.set_paused(true)
	check(paused and pause.is_paused, "P/Esc pause overlay works")
	pause.set_paused(false)
	check(not paused and not pause.is_paused, "pause overlay resumes")
	instance.queue_free()
	print("GAMEPLAY_MSD_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
