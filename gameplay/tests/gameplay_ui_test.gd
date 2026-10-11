## Optional demo presentation regression: interface/feedback/pause/victory.
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
	var arena := (load("res://gameplay/demo/gameplay_test.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await frames(4)
	var frame: Control = arena.get_node("HUD/Frame")
	var feedback: Node2D = arena.get_node("Feedback")
	var pause: CanvasLayer = arena.get_node("PauseOverlay")
	var victory: CanvasLayer = arena.get_node("VictoryOverlay")
	check(not pause.is_paused and not pause.get_node("Backdrop").visible, "pause overlay starts hidden")
	check(not victory.visible, "victory overlay starts hidden")
	check(frame.get("_shards") == 0 and frame.get("_braziers") == 0, "quest HUD starts empty")
	feedback.emit(Vector2(400, 350), "+1")
	check(feedback.active_count() >= 1, "feedback displays event burst")
	await frames(70)
	check(feedback.active_count() == 0, "feedback expires and does not leak")
	pause.set_paused(true)
	check(paused and pause.is_paused and pause.get_node("Backdrop").visible, "pause state darkens game and freezes tree")
	pause.set_paused(false)
	check(not paused and not pause.get_node("Backdrop").visible, "pause can resume cleanly")
	var shard: GameplayEmberShard = arena.get_node("Shards/Shard1")
	check(shard.collect_for(1), "shard pickup emits event with its position")
	check(frame.get("_shards") == 1, "HUD progress meter updates immediately")
	for index in [2, 3, 4, 5]:
		arena.get_node("Shards/Shard%d" % index).collect_for(2)
	for index in [1, 2, 3]:
		var brazier: GameplayEmberBrazier = arena.get_node("Braziers/Brazier%d" % index)
		brazier.try_ignite(brazier.global_position + Vector2(0, -18), 1)
	check(frame.get("_shards") == 5 and frame.get("_braziers") == 3, "HUD shows completed objectives")
	check(victory.visible, "objective completion reveals victory overlay")
	check("RUINS REKINDLED" in victory.get_node("Backdrop/Headline").text, "victory display contains headline")
	check("P1: 1" in victory.get_node("Backdrop/Stats").text, "victory displays contribution stats")
	arena.queue_free()
	print("GAMEPLAY_UI_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
