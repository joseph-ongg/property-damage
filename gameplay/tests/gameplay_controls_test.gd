## Full-vs-short jump, dash heading lock, aim feedback, and fallback prop fire.
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
	var scene := load("res://gameplay/demo/gameplay_test.tscn") as PackedScene
	var arena := scene.instantiate()
	root.add_child(arena)
	await frames(65)
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	check(p1.get_node("SparkAim") != null and p2.get_node("SparkAim") != null, "each player has an independent aim reticle")
	var p1_aim: Node2D = p1.get_node("SparkAim")
	check(p1_aim.target_world_position().distance_to(p1.global_position + Vector2(34, 0)) < 1.0, "aim marker matches spark world target")

	# Compare short tap and long hold without changing physics constants.
	p1.global_position = Vector2(580, 478)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	await frames(4)
	Input.action_press("p1_jump")
	await frames(3)
	Input.action_release("p1_jump")
	var short_peak := p1.global_position.y
	for _i in 33:
		await physics_frame
		short_peak = minf(short_peak, p1.global_position.y)
	p1.global_position = Vector2(580, 478)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	await frames(5)
	Input.action_press("p1_jump")
	var tall_peak := p1.global_position.y
	for _i in 35:
		await physics_frame
		tall_peak = minf(tall_peak, p1.global_position.y)
	Input.action_release("p1_jump")
	check(tall_peak < short_peak - 35.0, "holding jump reaches higher than a short tap")

	# The dash heading must not reverse while already dashing.
	p1.global_position = Vector2(520, 478)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	p1.dash.reset()
	await frames(4)
	Input.action_press("p1_left")
	await frames(3)
	Input.action_release("p1_left")
	check(p1.facing == -1, "direction can be chosen before starting a dash")
	Input.action_press("p1_dash")
	await frames(3) # Await the player physics tick before changing other inputs.
	Input.action_release("p1_dash")
	var x_start := p1.global_position.x
	Input.action_press("p1_right")
	await frames(5)
	check(p1.dash.active() and p1.dash.direction == -1 and p1.facing == -1, "opposite input does not flip the active dash")
	check(p1.global_position.x < x_start - 20, "dash continues moving in the locked direction")
	Input.action_release("p1_right")
	await frames(18)
	Input.action_press("p1_right")
	await frames(3)
	Input.action_release("p1_right")
	check(p1.facing == 1, "turning works again as soon as the dash ends")
	check(p1_aim.target_world_position().distance_to(p1.global_position + Vector2(34, 0)) < 1.0, "aim marker follows direction changes")

	# Landing dust is transient and independent from collision/Sim logic.
	p1.landing_fx.trigger()
	check(p1.landing_fx.is_active(), "landing dust appears when triggered")
	await frames(24)
	check(not p1.landing_fx.is_active(), "landing dust expires automatically")
	p1.global_position = Vector2(590, 450)
	p1.velocity = Vector2(0, 230)
	p1.motor.reset()
	await frames(20)
	check(p1.is_on_floor() and p1.landing_fx.is_active(), "natural landing triggers dust automatically")

	# Missing fire-grid storage does not block a correctly aimed brazier spark.
	var bridge: GameplayFireBridge = arena.get_node("FireBridge")
	bridge.grid_path = NodePath("../GridUnavailable")
	var brazier: GameplayEmberBrazier = arena.get_node("Braziers/Brazier1")
	check(not brazier.lit, "brazier starts unlit")
	p1.global_position = Vector2(293, 478)
	p1.velocity = Vector2.ZERO
	await frames(4)
	p1.spark._cooldown_remaining = 0.0
	Input.action_press("p1_spark")
	await frames(2)
	Input.action_release("p1_spark")
	check(brazier.lit, "spark still lights a nearby brazier without Simulation storage")
	check(arena.braziers_lit >= 1, "independent brazier event still updates the quest")
	arena.queue_free()
	print("GAMEPLAY_CONTROLS_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
