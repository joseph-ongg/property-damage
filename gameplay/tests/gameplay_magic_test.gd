## Ranged magic attack visual prototype, independent of Simulation and HP.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func _run() -> void:
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(65)
	var room := main.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var book: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	var pc: GameplayAppliance = room.get_node("Appliances/ComputerDevice")
	check(InputMap.has_action("p1_attack") and InputMap.has_action("p2_attack"), "distinct magic-attack keys registered")
	check(not book.scorched and not pc.charred, "book and computer start undamaged")
	p1.global_position = Vector2(249, 478)
	p1.velocity = Vector2.ZERO
	p1.facing = 1
	room.get_node("FireBridge").grid_path = NodePath("../NotReadyYet")
	await frames(4)
	Input.action_press("p1_attack")
	await frames(3)
	Input.action_release("p1_attack")
	check(p1._magic_cooldown > 0.0, "ranged attack consumes an independent cooldown")
	await frames(23)
	check(book.scorched, "P1 direction-based magic travels to and scorches a book")
	check(not pc.charred, "ranged magic doesn't damage distant computer")
	check(room.status_text.text.contains("MAGIC HIT"), "HUD identifies prototype magic impact")

	p2.global_position = Vector2(620, 384)
	p2.velocity = Vector2.ZERO
	p2.facing = -1
	await frames(4)
	Input.action_press("p2_attack")
	await frames(3)
	Input.action_release("p2_attack")
	await frames(24)
	check(pc.charred, "P2's left-facing magic damages the nearby computer")
	check(room.sparks_p1 == 0 and room.sparks_p2 == 0, "ranged magic does not fake Simulation Spark accounting")
	check(not room.has_node("VictoryOverlay"), "ranged magic introduces no unauthorized win condition")
	main.queue_free()
	print("GAMEPLAY_MAGIC_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
