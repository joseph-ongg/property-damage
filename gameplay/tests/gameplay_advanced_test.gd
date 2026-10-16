## Fixed-height double jumps, airborne inertia, book handling, appliance prototypes.
extends SceneTree

var failed: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(value: bool, reason: String) -> void:
	if value:
		print("PASS: ", reason)
	else:
		failed.append(reason)
		push_error("FAIL: " + reason)


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func _reset_player(player: GameplayPlayer, position: Vector2) -> void:
	player.global_position = position
	player.velocity = Vector2.ZERO
	player.motor.reset()


func _run() -> void:
	var scene := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(65)
	var room := scene.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	check(p1.motor.fixed_jump_height and p2.motor.fixed_jump_height, "default MSD uses fixed-height jumps for both players")
	check(p1.motor.max_jumps == 2 and p2.motor.max_jumps == 2, "both players receive exactly two jumps")
	check(p1.get_node("JumpCharges").visible and p2.get_node("JumpCharges").visible, "both players display remaining jump charges")
	check(p1.motor.preserve_air_momentum and p2.motor.preserve_air_momentum, "airborne input release preserves momentum")
	check(InputMap.has_action("p1_interact") and InputMap.has_action("p2_interact"), "each player registers a distinct interaction action")

	# Same fixed arc regardless of releasing the key early.
	_reset_player(p1, Vector2(600, 478))
	await frames(4)
	Input.action_press("p1_jump")
	await frames(3)
	Input.action_release("p1_jump")
	var tap_peak: float = p1.global_position.y
	for i in 45:
		await physics_frame
		tap_peak = minf(tap_peak, p1.global_position.y)
	_reset_player(p1, Vector2(600, 478))
	await frames(4)
	Input.action_press("p1_jump")
	var hold_peak: float = p1.global_position.y
	for i in 46:
		await physics_frame
		hold_peak = minf(hold_peak, p1.global_position.y)
	Input.action_release("p1_jump")
	check(absf(tap_peak - hold_peak) < 6.0, "tap and hold produce the same fixed-height first jump")

	_reset_player(p1, Vector2(600, 478))
	await frames(4)
	Input.action_press("p1_jump")
	await frames(8)
	Input.action_release("p1_jump")
	check(p1.motor.jumps_remaining() == 1, "first jump consumes one of two jumps")
	check(p1.get_node("JumpCharges").text.contains("◆"), "remaining second jump is visible")
	await frames(3)
	Input.action_press("p1_jump")
	await frames(3)
	Input.action_release("p1_jump")
	check(p1.motor.jumps_remaining() == 0 and p1.velocity.y < 0, "second jump resets upward velocity and consumes final charge")
	check(p1.get_node("JumpCharges").text == "·", "jump indicator clears after double jump")
	var just_before_third: float = p1.velocity.y
	await frames(3)
	Input.action_press("p1_jump")
	await frames(3)
	Input.action_release("p1_jump")
	check(p1.velocity.y > just_before_third, "third jump is rejected until landing")
	await frames(70)
	check(p1.is_on_floor() and p1.motor.jumps_remaining() == 2, "landing restores both jumps")

	_reset_player(p1, Vector2(615, 235))
	await frames(2)  # Let CharacterBody2D clear stale floor contacts after teleport.
	p1.velocity = Vector2(190, 0)
	await frames(10)
	check(absf(p1.velocity.x - 190.0) < 4.0, "releasing input in air retains horizontal speed")
	Input.action_press("p1_left")
	await frames(8)
	Input.action_release("p1_left")
	check(p1.velocity.x < 185.0, "air steering still allows changing velocity")

	# Real E input: pick up, follow player, throw, settle on a collision surface.
	_reset_player(p1, Vector2(310, 478))
	await frames(3)
	var book: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	Input.action_press("p1_interact")
	await frames(3)
	Input.action_release("p1_interact")
	check(book.carried_by == p1 and room.held_books.get(1) == book, "E picks up the nearby book")
	var book_before := book.global_position
	Input.action_press("p1_left")
	await frames(12)
	Input.action_release("p1_left")
	check(book.global_position.x < book_before.x - 15.0, "held book follows the player's movement")
	Input.action_press("p1_interact")
	await frames(3)
	Input.action_release("p1_interact")
	check(book.carried_by == null and book.flying and not room.held_books.has(1), "pressing E again throws the book")
	var thrown_start := book.global_position
	await frames(12)
	check(book.global_position.distance_to(thrown_start) > 15.0, "thrown book travels with independent velocity")
	await frames(120)
	check(not book.flying and book.global_position.y <= 485.1, "book settles on the arena without falling below the floor")

	# The second player can operate a device with their own key.
	_reset_player(p2, Vector2(795, 478))
	await frames(3)
	var fridge: GameplayAppliance = room.get_node("Appliances/FridgeDevice")
	Input.action_press("p2_interact")
	await frames(3)
	Input.action_release("p2_interact")
	check(fridge.switched_on, "P2 interaction key opens the fridge door")
	await frames(2)
	Input.action_press("p2_interact")
	await frames(3)
	Input.action_release("p2_interact")
	check(not fridge.switched_on, "P2 can close the fridge again")

	var fan: GameplayAppliance = room.get_node("Appliances/FanDevice")
	_reset_player(p1, Vector2(405, 381))
	await frames(3)
	check(fan.interact(p1), "fan can be switched on within range")
	await frames(2)
	check(p1.motor.environment_acceleration_x < -100, "fan applies a real leftward environmental force")
	var ac: GameplayAppliance = room.get_node("Appliances/ACDevice")
	_reset_player(p1, Vector2(646, 478))
	await frames(3)
	check(ac.interact(p1), "AC can be switched on")
	await frames(2)
	check(p1.motor.speed_scale < 1.0, "AC region scales player movement speed")

	var computer: GameplayAppliance = room.get_node("Appliances/ComputerDevice")
	check(computer.device == GameplayAppliance.Device.COMPUTER, "computer device exists separately")
	_reset_player(p1, Vector2(518, 384))
	p1.facing = 1
	p1.spark._cooldown_remaining = 0.0
	await frames(3)
	Input.action_press("p1_spark")
	await frames(3)
	Input.action_release("p1_spark")
	check(computer.charred and not computer.switched_on, "real Spark shorts the computer without changing Simulation storage")
	check(not computer.receive_spark(computer.global_position, 2), "already destroyed computer cannot be triggered repeatedly")
	check(not room.has_node("VictoryOverlay"), "optional interactions add no invented victory rule")
	scene.queue_free()
	print("GAMEPLAY_ADVANCED_SUMMARY failures=", failed.size())
	quit(0 if failed.is_empty() else 1)
