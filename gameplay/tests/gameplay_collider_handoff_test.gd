## Regression: one-way drop must work for both the 40px Gameplay collider and
## Angela's 64px CharacterBody2D rectangle, without changing Simulation files.
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


func _run() -> void:
	var main: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(65)
	var room: Node2D = main.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var table: StaticBody2D = room.get_node("TableTop")
	var collider: CollisionShape2D = p1.get_node("CollisionShape2D")
	check(collider.shape is RectangleShape2D, "Gameplay player has a rectangle collider")
	check(is_equal_approx((collider.shape as RectangleShape2D).size.y, 40.0), "default Gameplay player uses 40px collider")
	check(is_equal_approx((p2.get_node("CollisionShape2D").shape as RectangleShape2D).size.y, 40.0), "the other player's collider is still 40px")

	# Modify only the test instance; the scene and P2 remain unchanged.
	collider.shape = collider.shape.duplicate()
	(collider.shape as RectangleShape2D).size = Vector2(32, 64)
	check(is_equal_approx(p1.platform_drop._player_half_height(p1), 32.0), "drop helper reads the 64px half-height dynamically")
	p1.global_position = Vector2(435, 347)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	await frames(35)
	check(p1.is_on_floor() and p1.global_position.y < 390, "64px player lands safely on table")
	check(p1.platform_drop.try_drop(p1), "64px player can initiate a table drop")
	var stopped_early := false
	for i in 90:
		await physics_frame
		if not p1.platform_drop.is_dropping():
			var top := p1.platform_drop._player_shape_center_y(p1) - p1.platform_drop._player_half_height(p1)
			var platform_bottom := table.global_position.y + 6.0
			stopped_early = top <= platform_bottom + 1.0
			break
	check(not stopped_early, "collision is restored only after the entire 64px body clears the platform")
	await frames(55)
	check(p1.is_on_floor() and p1.global_position.y > 450, "resized player lands on solid floor after dropping")
	check(is_equal_approx(p1.platform_drop._player_half_height(p1), 32.0) and is_equal_approx(p2.platform_drop._player_half_height(p2), 20.0), "per-player collider sizing never leaks between P1 and P2")

	# Same drop method still rejects solid world collision at the larger size.
	check(not p1.platform_drop.try_drop(p1), "64px collider cannot phase through solid floor")
	main.queue_free()
	print("COLLIDER_HANDOFF_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
