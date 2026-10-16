## Regression tests for jump assistance, spark cooldown and bridge fallbacks.
## Godot --headless --path . --script res://gameplay/tests/gameplay_edge_test.gd
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
	for _i in range(n):
		await physics_frame


func _run() -> void:
	var arena := (load("res://gameplay/demo/gameplay_test.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await frames(8)
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	var bridge: GameplayFireBridge = arena.get_node("FireBridge")
	var grid_path := bridge.grid_path

	# Spark cooldown: no double-fire; fresh spark once recharged.
	var first := p2.spark.cast_spark(p2.global_position, p2.facing, bridge, p2.tint)
	var second := p2.spark.cast_spark(p2.global_position, p2.facing, bridge, p2.tint)
	check(first and not second and not p2.spark.is_ready(), "spark respects cooldown and cannot double-fire")
	await frames(20)
	check(p2.spark.is_ready() and p2.spark.cooldown_ratio() == 0.0, "spark recharges after cooldown")
	bridge.grid_path = NodePath("../MissingGrid")
	check(not bridge.ignite_world(p1.global_position) and not bridge.is_burning_world(p1.global_position), "missing grid fails without crashing")
	bridge.grid_path = grid_path
	check(bridge.ignite_world(p1.global_position + Vector2(34, 0)), "grid can be reconnected at runtime")

	# Coyote time: start grounded on the one-way platform, leave the edge, jump soon after.
	p1.global_position = Vector2(240, 400)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	await frames(10)
	check(p1.is_on_floor(), "edge test starts on a platform")
	Input.action_press("p1_right")
	var left_platform := false
	for _i in range(80):
		await physics_frame
		if not p1.is_on_floor():
			left_platform = true
			break
	Input.action_release("p1_right")
	check(left_platform, "walked off the platform edge")
	Input.action_press("p1_jump")
	await frames(2)
	Input.action_release("p1_jump")
	check(p1.velocity.y < -100, "coyote jump works just after leaving a platform")

	# Jump buffer: press jump just before falling onto floor, auto-launch when landing.
	p1.global_position = Vector2(590, 455)
	p1.velocity = Vector2(0, 180)
	p1.motor.reset()
	await frames(2)
	Input.action_press("p1_jump")
	await frames(2)
	Input.action_release("p1_jump")
	await frames(19)
	check(p1.global_position.y < 450 and p1.velocity.y < 0, "buffered jump fires on landing")

	# No phantom jump when input buffer expires long before landing.
	p1.global_position = Vector2(590, 240)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	await frames(2)
	Input.action_press("p1_jump")
	await frames(2)
	Input.action_release("p1_jump")
	await frames(90)
	check(p1.is_on_floor() and p1.velocity.y >= 0, "expired jump buffer does not auto-launch later")

	# Recovery for exceptional out-of-bounds falls.
	p1.global_position = Vector2(600, 650)
	p1.velocity = Vector2(0, 80)
	await frames(1)
	check(p1.global_position == Vector2(130, 460) and p1.velocity == Vector2.ZERO, "out-of-bounds rescue resets to spawn")

	arena.queue_free()
	print("GAMEPLAY_EDGE_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
