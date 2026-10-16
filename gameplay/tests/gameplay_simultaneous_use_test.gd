## Two real keyboard actions on the same frame must not cancel one another.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
func frames(n: int) -> void:
	for _i in n: await physics_frame
func move_player(p: GameplayPlayer, location: Vector2) -> void:
	p.global_position = location
	p.velocity = Vector2.ZERO
	p.motor.reset()

func _run() -> void:
	var scene: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(65)
	var room: Node2D = scene.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var fridge: GameplayAppliance = room.get_node("Appliances/FridgeDevice")
	var transitions: Array[bool] = []
	fridge.state_changed.connect(func(_device: int, state: bool, _index: int): transitions.append(state))
	move_player(p1, Vector2(761, 478))
	move_player(p2, Vector2(792, 478))
	await frames(4)
	check(room.get_interaction_offer(p1).get("target") == fridge and room.get_interaction_offer(p2).get("target") == fridge,
		"both players actually target the same nearby fridge")
	Input.action_press("p1_interact")
	Input.action_press("p2_interact")
	await frames(2)
	Input.action_release("p1_interact")
	Input.action_release("p2_interact")
	check(fridge.switched_on, "simultaneous interaction opens the fridge once instead of canceling")
	check(transitions == [true], "same-frame P1/P2 interaction emits exactly one state transition")
	await frames(4)
	Input.action_press("p2_interact")
	await frames(2)
	Input.action_release("p2_interact")
	check(not fridge.switched_on and transitions == [true, false], "other player can close fridge on a later deliberate press")

	# The same race affects every switchable appliance, not just the fridge.
	var ac: GameplayAppliance = room.get_node("Appliances/ACDevice")
	var ac_events: Array[bool] = []
	ac.state_changed.connect(func(_device: int, state: bool, _index: int): ac_events.append(state))
	move_player(p1, Vector2(647, 478))
	move_player(p2, Vector2(654, 478))
	await frames(4)
	check(room.get_interaction_offer(p1).get("target") == ac and room.get_interaction_offer(p2).get("target") == ac,
		"both players actually target the same air conditioner")
	Input.action_press("p1_interact")
	Input.action_press("p2_interact")
	await frames(2)
	Input.action_release("p1_interact")
	Input.action_release("p2_interact")
	check(ac.switched_on and ac_events == [true], "simultaneous AC input activates cooling exactly once")
	await frames(2)
	check(p1.motor.speed_scale < 0.5 and p2.motor.speed_scale < 0.5,
		"cooling applies to both players after a shared activation")
	await frames(4)
	Input.action_press("p2_interact")
	await frames(2)
	Input.action_release("p2_interact")
	check(not ac.switched_on and ac_events == [true, false], "another player may turn the same AC off on a new press")

	# Frame gating is per appliance, not globally for the room. Independently
	# controlled devices must still work when both players press at once.
	move_player(p1, Vector2(647, 478))
	move_player(p2, Vector2(795, 478))
	await frames(4)
	check(room.get_interaction_offer(p1).get("target") == ac and room.get_interaction_offer(p2).get("target") == fridge,
		"separate players target two different appliances")
	Input.action_press("p1_interact")
	Input.action_press("p2_interact")
	await frames(2)
	Input.action_release("p1_interact")
	Input.action_release("p2_interact")
	check(ac.switched_on and fridge.switched_on, "different appliances respond independently in the same frame")
	check(ac_events == [true, false, true] and transitions == [true, false, true],
		"independent appliances each emit one transition")
	scene.queue_free()
	print("SIMULTANEOUS_USE_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
