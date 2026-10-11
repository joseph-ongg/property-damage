## Validate the live floor-level E interaction and visible push from the tabletop fan.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, detail: String) -> void:
	if ok:
		print("PASS: ", detail)
	else:
		failures.append(detail)
		push_error("FAIL: " + detail)


func frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _run() -> void:
	var instance: Node2D = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(instance)
	await frames(65)
	var room: Node2D = instance.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var fan: GameplayAppliance = room.get_node("Appliances/FanDevice")
	var hints: Node2D = room.get_node("InteractionHints")
	var states: Node2D = room.get_node("PlayerConditions")

	# A standing player should be able to interact with the tabletop appliance.
	p1.global_position = Vector2(413, 478)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	await frames(4)
	check(p1.is_on_floor(), "P1 is standing on the actual room floor near the fan")
	check(fan.can_interact(p1), "the fan's tabletop controls are reachable from the floor")
	check(room.get_interaction_offer(p1).get("target") == fan, "nearest interaction selects the fan")
	check(hints.hint_for(p1) == "E  TURN ON FAN", "the prompt offers a usable E key")

	Input.action_press("p1_interact")
	await frames(3)
	Input.action_release("p1_interact")
	check(fan.switched_on, "pressing E actually switches on the fan")
	check(states.get_condition(p1) == "WIND", "the WIND effect is visible while inside fan range")
	var start_x: float = p1.global_position.x
	await frames(18)
	check(p1.global_position.x < start_x - 5.0, "fan visibly moves a grounded idle player")
	check(p1.velocity.x < -45.0, "fan accelerates a grounded player against idle friction")
	check(is_equal_approx(p2.motor.environment_acceleration_x, 0.0), "distant P2 is unaffected by the fan")
	check(room.get_interaction_offer(p1).get("target") == fan, "fan remains operable after a brief push")

	Input.action_press("p1_interact")
	await frames(3)
	Input.action_release("p1_interact")
	check(not fan.switched_on, "pressing E again switches the fan off")
	await frames(18)
	check(is_zero_approx(p1.motor.environment_acceleration_x), "turning fan off removes wind force")
	check(absf(p1.velocity.x) < 3.0, "normal ground friction stops idle player after wind stops")
	check(states.get_condition(p1).is_empty(), "WIND status disappears when fan is off")

	# The same appliance must work with the second player's independent key.
	p1.global_position = Vector2(130, 478)
	p1.velocity = Vector2.ZERO
	p2.global_position = Vector2(413, 478)
	p2.velocity = Vector2.ZERO
	p2.motor.reset()
	await frames(4)
	check(hints.hint_for(p2) == "SHIFT  TURN ON FAN", "P2 sees Shift instead of E at the floor")
	Input.action_press("p2_interact")
	await frames(3)
	Input.action_release("p2_interact")
	check(fan.switched_on and states.get_condition(p2) == "WIND", "P2 Shift turns fan on with wind feedback")
	var p2_start_x := p2.global_position.x
	await frames(12)
	check(p2.global_position.x < p2_start_x - 3.0, "P2 also experiences real fan push")
	check(states.get_condition(p1).is_empty(), "P1 outside radius stays unaffected by P2 interaction")
	Input.action_press("p2_interact")
	await frames(3)
	Input.action_release("p2_interact")
	check(not fan.switched_on, "P2 can independently turn the fan back off")

	instance.queue_free()
	print("GAMEPLAY_FAN_PLAYTEST_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
