## Test the compact HUD, help input/pause coordination and target hints.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		push_error("FAIL: " + message)
		failures.append(message)


func frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _key(physical: Key, logical: Key = KEY_NONE) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = physical
	ev.keycode = logical
	return ev


func _run() -> void:
	var arena := (load("res://gameplay/demo/gameplay_test.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await frames(4)
	var hud: CanvasLayer = arena.get_node("HUD")
	var help: CanvasLayer = arena.get_node("HelpOverlay")
	var pause: CanvasLayer = arena.get_node("PauseOverlay")
	var guides: Node2D = arena.get_node("ObjectiveGuides")
	check(not help.is_open and not help.visible, "help initially hidden")
	check(not hud.get_node("Controls").visible and not hud.get_node("ControlsP2").visible, "verbose controls removed from default HUD")
	check(hud.get_node("Title").offset_bottom < 46.0 and hud.get_node("Quest").offset_bottom < 100.0, "essential HUD text fits compact space")
	check(guides.remaining_shards() == 5 and guides.remaining_braziers() == 3, "objective markers track all eight goals")
	check(not paused, "demo starts unpaused")

	help._unhandled_input(_key(KEY_H))
	check(help.is_open and help.visible and paused, "H shows guide and pauses movement")
	check("ENTER" in help.get_node("Backdrop/P2Keys").text, "help shows full P2 mapping")
	pause._unhandled_input(_key(KEY_P))
	check(not pause.is_paused and help.is_open and paused, "pause cannot overlap help")
	help._unhandled_input(_key(KEY_H))
	check(not help.is_open and not help.visible and not paused, "H resumes gameplay and hides help")
	pause.set_paused(true)
	help._unhandled_input(_key(KEY_H))
	check(not help.is_open and pause.is_paused and paused, "help cannot open over paused game")
	pause.set_paused(false)

	# Logical-only keycodes are used by accessibility/synthetic input tools.
	help._unhandled_input(_key(KEY_NONE, KEY_H))
	check(help.is_open and paused, "logical H also opens help")
	help._unhandled_input(_key(KEY_NONE, KEY_H))
	check(not help.is_open and not paused, "logical H also closes help")

	var first: GameplayEmberShard = arena.get_node("Shards/Shard1")
	check(first.collect_for(1), "shard can be collected while guide remains closed")
	check(guides.remaining_shards() == 4, "collected shard loses its objective marker")
	var brazier: GameplayEmberBrazier = arena.get_node("Braziers/Brazier1")
	var player1: GameplayPlayer = arena.get_node("Player1")
	player1.global_position = Vector2(293, 478)
	player1.facing = 1
	await frames(3)
	check(guides.is_brazier_targetable(brazier), "nearby correctly aimed fire shrine receives green targeting ring")
	player1.facing = -1
	await frames(3)
	check(not guides.is_brazier_targetable(brazier), "ring disappears when facing away from shrine")
	check(brazier.try_ignite(Vector2(327, 480), 1), "spark target ignites test shrine")
	check(guides.remaining_braziers() == 2, "lit shrine loses objective marker")
	check(not guides.is_brazier_targetable(brazier), "completed shrine is no longer targetable")
	arena.get_node("VictoryOverlay").visible = true
	help._unhandled_input(_key(KEY_H))
	check(not help.is_open and not paused, "help does not interrupt completed victory screen")
	arena.queue_free()
	print("GAMEPLAY_GUIDANCE_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
