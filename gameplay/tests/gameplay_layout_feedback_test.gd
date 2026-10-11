## 实际操作合同：桌面留白、附近提示与按键执行一致、空调真实减速与恢复。
## EN: Interaction tests cover desk spacing, actionable prompts and AC speed changes.
extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, name: String) -> void:
	if ok:
		print("PASS: ", name)
	else:
		failures.append(name)
		push_error("FAIL: " + name)

func frames(n: int) -> void:
	for _i in n:
		await physics_frame

func _reset(p: GameplayPlayer, pos: Vector2) -> void:
	p.global_position = pos
	p.velocity = Vector2.ZERO
	p.motor.reset()

func _press(action: String) -> void:
	Input.action_press(action)
	await frames(3)
	Input.action_release(action)

func _run() -> void:
	var instance := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(instance)
	await frames(65)
	var arena: Node2D = instance.get_node("GameplayMSD")
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	var hints: Node2D = arena.get_node("InteractionHints")
	var indicators: Node2D = arena.get_node("PlayerConditions")
	var ac: GameplayAppliance = arena.get_node("Appliances/ACDevice")
	var computer: GameplayAppliance = arena.get_node("Appliances/ComputerDevice")
	var fan: GameplayAppliance = arena.get_node("Appliances/FanDevice")
	var table_book: GameplayBurnableProp = arena.get_node("Books/TableBooks")
	check(not hints == null and not indicators == null, "context hints and player status feedback exist")
	check(computer.global_position.x - 22 > table_book.global_position.x + table_book.width * 0.5 + 20.0, "computer and book are separated on desktop")
	check(table_book.global_position.x - table_book.width * 0.5 > fan.global_position.x + 18.0, "fan and books are separated")
	check(absf(computer.global_position.y + 7.0 - 411.0) < 1.0, "computer base rests on table top")
	check(is_equal_approx(ac.cold_speed_scale, 0.45) and ac.effect_radius >= 125.0, "AC chill range and slowed speed are noticeable")
	check(hints.hint_for(p1).is_empty() and hints.hint_for(p2).is_empty(), "faraway players have no irrelevant interaction prompts")

	# P1 sees the same appliance offered by the actual E interaction.
	_reset(p1, Vector2(647, 478))
	await frames(4)
	check(arena.get_interaction_offer(p1).get("target") == ac, "nearby P1 targets AC rather than distant fridge")
	check(hints.hint_for(p1) == "E  TURN ON AIR CONDITIONER", "P1 prompt states exact usable key and action")
	check(indicators.get_condition(p1).is_empty(), "AC is off initially; player is not slowed")
	await _press("p1_interact")
	await frames(3)
	check(ac.switched_on, "E activates actual AC")
	check(is_equal_approx(p1.motor.speed_scale, 0.45), "active AC sets movement speed factor to 45 percent")
	check(indicators.get_condition(p1) == "SLOW", "chilled player receives visible status text")
	check(hints.hint_for(p1) == "E  TURN OFF AIR CONDITIONER", "prompt changes to turn-off after activation")
	Input.action_press("p1_right")
	await frames(18)
	Input.action_release("p1_right")
	var chilled_speed := p1.velocity.x
	check(chilled_speed > 85.0 and chilled_speed < 125.0, "player physically moves slower near active AC")
	await _press("p1_interact")
	await frames(3)
	check(not ac.switched_on and is_equal_approx(p1.motor.speed_scale, 1.0), "same E turns off AC and restores speed")
	Input.action_press("p1_right")
	await frames(16)
	Input.action_release("p1_right")
	check(p1.velocity.x > chilled_speed + 80.0, "normal movement is measurably faster without AC")

	# 空中惯性在无空调时保留；进入冷气区后逐步降到低速上限。
	# EN: Keep air momentum without AC; gradually enforce the lower cap inside its zone.
	_reset(p1, Vector2(649, 403))
	await frames(2)
	p1.velocity = Vector2(208.0, 0.0)
	check(is_equal_approx(p1.motor.speed_scale, 1.0), "without cooling, regular airborne momentum is not reduced")
	check(ac.interact(p1), "AC can be re-enabled from the air inside interaction radius")
	await frames(10)
	check(p1.motor.speed_scale < 0.5 and p1.velocity.x < 180.0, "AC also slows inherited airborne momentum")
	check(ac.interact(p1), "AC can be turned back off while airborne")

	# P2 controls work independently and use their own hint key.
	_reset(p1, Vector2(200, 478))
	_reset(p2, Vector2(654, 478))
	await frames(4)
	check(hints.hint_for(p2) == "SHIFT  TURN ON AIR CONDITIONER", "P2 uses SHIFT instead of E")
	await _press("p2_interact")
	await frames(3)
	check(ac.switched_on and is_equal_approx(p2.motor.speed_scale, 0.45), "P2 switches on AC and is slowed")
	check(is_equal_approx(p1.motor.speed_scale, 1.0), "remote P1 is not slowed")
	_reset(p2, Vector2(884, 478))
	await frames(4)
	check(is_equal_approx(p2.motor.speed_scale, 1.0) and indicators.get_condition(p2).is_empty(), "speed restores after leaving AC range")

	# Prefer nearby book to appliance; carry prompt instantly becomes THROW.
	_reset(p1, Vector2(474, 396))
	await frames(4)
	check(arena.get_interaction_offer(p1).get("target") == table_book, "nearby book gets interaction priority on desk")
	check(hints.hint_for(p1) == "E  PICK BOOK", "books show pickup hint")
	await _press("p1_interact")
	check(table_book.carried_by == p1 and hints.hint_for(p1) == "E  THROW BOOK", "E pickup changes hint to throw")
	await frames(3)
	await _press("p1_interact")
	check(table_book.carried_by == null, "E throws held book; hint no longer says throw")

	# Charred computer can no longer promise an interactive action.
	_reset(p1, Vector2(553, 403))
	await frames(4)
	check(arena.get_interaction_offer(p1).get("target") == computer, "monitor is identified as computer interaction")
	check(hints.hint_for(p1).contains("COMPUTER"), "monitor hint uses the correct device name")
	check(computer.receive_spark(computer.global_position, 1), "computer can be charred")
	await frames(2)
	check(not hints.hint_for(p1).contains("COMPUTER"), "destroyed computer no longer advertises usable interaction")
	instance.queue_free()
	print("LAYOUT_FEEDBACK_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
