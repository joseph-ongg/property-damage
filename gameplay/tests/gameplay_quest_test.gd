## Tests the optional game layer: dash, pickups, fire objectives, combo and win.
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
	var packed := load("res://gameplay/demo/gameplay_test.tscn") as PackedScene
	check(packed != null, "pixel-art game scene loads")
	if packed == null:
		quit(1)
		return
	var arena := packed.instantiate()
	root.add_child(arena)
	await frames(65)
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	var controller = arena
	check(InputMap.has_action("p1_dash") and InputMap.has_action("p2_dash"), "both dash keys registered")
	check(p1.sprite.texture != null and p2.sprite.texture != null, "both original mage sprites loaded")
	check(p1.dash.ready() and p2.dash.ready(), "dash begins ready for each player")
	var start_x: float = p1.global_position.x
	Input.action_press("p1_dash")
	await frames(1)
	Input.action_release("p1_dash")
	await frames(6)
	check(p1.global_position.x > start_x + 40.0, "P1 dash generates forward burst")
	check(not p1.dash.ready(), "dash imposes cooldown")
	check(not p1.dash.begin(), "dash cannot be retriggered during cooldown")
	await frames(60)
	check(p1.dash.ready(), "dash becomes available after cooldown")
	# P2's dash uses a completely separate action and cooldown.
	var p2_start_x := p2.global_position.x
	Input.action_press("p2_dash")
	await frames(3)
	Input.action_release("p2_dash")
	check(p2.global_position.x < p2_start_x - 10, "P2 slash dash moves left independently")
	check(not p2.dash.ready(), "P2 dash has its own cooldown")
	# Dash should have naturally collected the first ground shard.
	var first: GameplayEmberShard = arena.get_node("Shards/Shard1")
	check(first.taken and controller.shards_p1 >= 1, "running into a shard triggers Area2D pickup")
	check(not first.collect_for(1), "a collected shard cannot be collected twice")
	for index: int in [2,3,4,5]:
		var shard: GameplayEmberShard = arena.get_node("Shards/Shard%d" % index)
		var owner := 1 if index % 2 == 0 else 2
		check(shard.collect_for(owner), "remaining collectible %d emits collection event" % index)
	check(controller.shards_p1 + controller.shards_p2 == 5, "both players contribute to shared shard quest")
	# Real spark input at a brazier's cup position.
	p1.global_position = Vector2(295, 478)
	p1.velocity = Vector2.ZERO
	await frames(2)
	Input.action_press("p1_spark")
	await frames(3)
	Input.action_release("p1_spark")
	check(arena.get_node("Braziers/Brazier1").lit, "P1 spark lights near ground brazier")
	# P2 faces left, so place them to the right of brazier3.
	p2.global_position = Vector2(704, 478)
	p2.velocity = Vector2.ZERO
	await frames(2)
	Input.action_press("p2_spark")
	await frames(3)
	Input.action_release("p2_spark")
	check(arena.get_node("Braziers/Brazier3").lit, "P2 can light brazier from left-facing side")
	check(controller.combo_count >= 1, "alternating sparks within window triggers duo combo")
	# Upper brazier: direct scene API at the spark's physical target.
	var upper: GameplayEmberBrazier = arena.get_node("Braziers/Brazier2")
	check(not upper.try_ignite(Vector2(200, 200), 1), "brazier ignores distant sparks")
	check(upper.try_ignite(Vector2(470, 320), 1), "platform brazier accepts valid spark target")
	check(not upper.try_ignite(Vector2(470, 320), 2), "lit brazier cannot award points again")
	check(controller.braziers_lit == 3, "all three fire shrines contribute to quest")
	check(controller._won and "RUINS RESTORED" in controller.status_text.text, "collect-all + light-all triggers win state")
	check(p1.dash.begin(), "dash API stays callable after quest")
	arena.queue_free()
	print("GAMEPLAY_QUEST_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
