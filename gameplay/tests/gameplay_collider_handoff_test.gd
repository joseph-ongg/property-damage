## The standard Gameplay collider is 32x64, matching Angela's shape dimensions.
## Keep the visual feet planted with a -12px collider offset; platform drop also
## supports Angela's centered collider and older 22x40 player scenes.
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
	var p2_collider: CollisionShape2D = p2.get_node("CollisionShape2D")
	check(collider.shape is RectangleShape2D, "player prefab uses a rectangle collider")
	check((collider.shape as RectangleShape2D).size == Vector2(32, 64), "P1 matches Angela's 32x64 collider dimensions")
	check((p2_collider.shape as RectangleShape2D).size == Vector2(32, 64), "P2 also matches Angela's 32x64 collider dimensions")
	check(collider.position == Vector2(0, -12) and p2_collider.position == Vector2(0, -12), "both Gameplay colliders preserve the existing sprite/foot baseline")
	check(p1.is_on_floor() and p2.is_on_floor() and absf(p1.global_position.y - 478.0) < 1.0, "standard players stand at the original floor height")

	# In each case drop through a real one-way table, then land on solid ground.
	# Mutate just this test instance's shape so the other player is not affected.
	collider.shape = collider.shape.duplicate()
	var variants := [
		{"name": "Gameplay offset 32x64", "size": Vector2(32, 64), "offset": Vector2(0, -12), "start": 347.0},
		{"name": "Angela centered 32x64", "size": Vector2(32, 64), "offset": Vector2.ZERO, "start": 335.0},
		{"name": "legacy centered 22x40", "size": Vector2(22, 40), "offset": Vector2.ZERO, "start": 347.0},
	]
	for variant: Dictionary in variants:
		var label: String = variant["name"]
		(collider.shape as RectangleShape2D).size = variant["size"]
		collider.position = variant["offset"]
		p1.global_position = Vector2(435, variant["start"])
		p1.velocity = Vector2.ZERO
		p1.motor.reset()
		p1.platform_drop.reset(p1)
		await frames(35)
		var half_height: float = variant["size"].y * 0.5
		check(is_equal_approx(p1.platform_drop._player_half_height(p1), half_height), label + " reads actual half-height")
		check(p1.is_on_floor() and p1.global_position.y < 400, label + " lands on one-way table")
		check(p1.platform_drop.try_drop(p1), label + " begins drop")
		var restored_too_early := false
		var restored := false
		for _i in 90:
			await physics_frame
			if not p1.platform_drop.is_dropping():
				var top := p1.platform_drop._player_shape_center_y(p1) - p1.platform_drop._player_half_height(p1)
				var bottom_of_table: float = table.global_position.y + 6.0
				restored_too_early = top <= bottom_of_table + 1.0
				restored = true
				break
		check(restored and not restored_too_early, label + " restores platform after whole body clears")
		await frames(55)
		check(p1.is_on_floor() and p1.global_position.y > 450, label + " lands on solid floor")
		check(not p1.platform_drop.try_drop(p1), label + " cannot drop through solid floor")

	check((p2_collider.shape as RectangleShape2D).size == Vector2(32, 64) and p2_collider.position == Vector2(0, -12), "P1 variations never change P2's default shape")
	main.queue_free()
	print("COLLIDER_HANDOFF_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
