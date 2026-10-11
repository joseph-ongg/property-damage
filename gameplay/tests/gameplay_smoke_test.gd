## Run: Godot --headless --path . --script res://gameplay/tests/gameplay_smoke_test.gd
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error("FAIL: " + message)
		failures.append(message)


func _frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _run() -> void:
	var scene: PackedScene = load("res://gameplay/demo/gameplay_test.tscn")
	check(scene != null, "playable test scene loads")
	if scene == null:
		quit(1)
		return
	var arena := scene.instantiate()
	root.add_child(arena)
	await _frames(5)
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	var bridge: GameplayFireBridge = arena.get_node("FireBridge")
	var grid: Node2D = arena.get_node("DemoFireGrid")
	check(InputMap.has_action("p1_jump") and InputMap.has_action("p2_spark"), "isolated controls registered")
	check(p1.collision_layer == 2 and p1.collision_mask == 1, "P1 only collides with world")
	check(p2.collision_layer == 2 and p2.collision_mask == 1, "P2 passes through P1")
	check(p1.facing == 1 and p2.facing == -1, "players start facing opposite directions")
	for path: String in ["LowerPlatform", "UpperPlatform", "RightPlatform"]:
		var platform: CollisionShape2D = arena.get_node(path + "/CollisionShape2D")
		check(platform.one_way_collision, path + " has one-way collision")
	await _frames(65)
	check(p1.is_on_floor() and p2.is_on_floor(), "players land on solid floor")
	var old_x := p1.global_position.x
	Input.action_press("p1_right")
	await _frames(22)
	Input.action_release("p1_right")
	check(p1.global_position.x > old_x + 20.0, "P1 moves with own right action")
	old_x = p2.global_position.x
	Input.action_press("p2_left")
	await _frames(22)
	Input.action_release("p2_left")
	check(p2.global_position.x < old_x - 20.0 and p2.facing == -1, "P2 moves independently and faces left")
	var floor_y := p1.global_position.y
	Input.action_press("p1_jump")
	await _frames(3)
	Input.action_release("p1_jump")
	check(p1.global_position.y < floor_y - 2.0, "P1 jumps while on floor")
	floor_y = p2.global_position.y
	Input.action_press("p2_jump")
	await _frames(3)
	Input.action_release("p2_jump")
	check(p2.global_position.y < floor_y - 2.0, "P2 jumps independently with arrow up")
	# Verify facing-dependent spark uses the world-to-cell grid API.
	var target := p2.global_position + Vector2(-34, 0)
	var cell: Vector2i = grid.call("world_to_cell", target)
	var success := p2.spark.cast_spark(p2.global_position, -1, bridge, p2.tint)
	check(success and grid.call("is_burning", cell.x, cell.y), "spark ignites the cell in facing direction")
	check(bridge.is_burning_world(target), "fire bridge reads the current burning cell")
	await _frames(20)  # Let spark cooldown expire.
	var p2_second_target := p2.global_position + Vector2(-34, 0)
	var second_cell: Vector2i = grid.call("world_to_cell", p2_second_target)
	Input.action_press("p2_spark")
	await _frames(3)
	Input.action_release("p2_spark")
	check(grid.call("is_burning", second_cell.x, second_cell.y), "P2 ENTER spark action triggers ignition")
	check(not bridge.ignite_world(Vector2(-100, -100)), "out-of-bounds sparks are safely ignored")
	# Move left into solid wall and verify no horizontal escape.
	p1.global_position = Vector2(25, 460)
	p1.velocity = Vector2.ZERO
	Input.action_press("p1_left")
	await _frames(70)
	Input.action_release("p1_left")
	check(p1.global_position.x >= 10.0, "world wall keeps P1 on screen")
	# Landing after jump should restore grounded state.
	await _frames(95)
	check(p1.is_on_floor(), "standing on the world floor after movement")
	# Jump from below the one-way platform; land on it from above.
	p1.global_position = Vector2(240, 476)
	p1.velocity = Vector2.ZERO
	await _frames(5)
	Input.action_press("p1_jump")
	await _frames(2)
	Input.action_release("p1_jump")
	await _frames(23)
	check(p1.global_position.y < 400, "P1 can jump through one-way platform from underneath")
	await _frames(45)
	check(p1.is_on_floor() and absf(p1.global_position.y - 400.0) < 3.0, "P1 lands and stands ON one-way platform")
	var p1_fire_target := p1.global_position + Vector2(float(p1.facing) * 34.0, 0)
	var p1_cell: Vector2i = grid.call("world_to_cell", p1_fire_target)
	Input.action_press("p1_spark")
	await _frames(3)
	Input.action_release("p1_spark")
	check(grid.call("is_burning", p1_cell.x, p1_cell.y), "P1 F spark action triggers ignition")
	arena.queue_free()
	print("GAMEPLAY_SMOKE_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
