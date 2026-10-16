## Exercise real P, Esc, and R key events across paused and active MSD scenes.
## Regression: consuming an event after reload_current_scene() accesses a freed Viewport.
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
		await process_frame


func press_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)


func release_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)


func _run() -> void:
	var scene: PackedScene = load("res://gameplay/playtest_main.tscn")
	check(scene != null, "default scene is available for restart playtest")
	if scene == null:
		quit(1)
		return
	var initial_scene: Node2D = scene.instantiate()
	root.add_child(initial_scene)
	current_scene = initial_scene
	await frames(10)
	var initial_pause: CanvasLayer = current_scene.get_node("GameplayMSD/PauseOverlay")
	check(not paused and not initial_pause.is_paused, "game starts unpaused")

	press_key(KEY_P)
	await frames(2)
	release_key(KEY_P)
	check(paused and initial_pause.is_paused, "P pauses the active scene through real input")

	press_key(KEY_R)
	await frames(5)
	release_key(KEY_R)
	check(not paused, "R in pause menu unpauses the tree")
	check(current_scene != null and current_scene != initial_scene, "R in pause menu reloads the scene")
	if current_scene == null:
		quit(1)
		return
	var second_scene := current_scene
	var second_room: Node2D = second_scene.get_node("GameplayMSD")
	check(second_room.sparks_p1 == 0 and second_room.sparks_p2 == 0, "paused restart resets spark state")
	check(not second_room.get_node("PauseOverlay").is_paused, "new pause overlay starts closed")

	press_key(KEY_ESCAPE)
	await frames(2)
	release_key(KEY_ESCAPE)
	check(paused and second_room.get_node("PauseOverlay").is_paused, "Esc can pause the restarted scene")
	press_key(KEY_ESCAPE)
	await frames(2)
	release_key(KEY_ESCAPE)
	check(not paused and not second_room.get_node("PauseOverlay").is_paused, "Esc resumes the restarted scene")

	press_key(KEY_R)
	await frames(5)
	release_key(KEY_R)
	check(current_scene != null and current_scene != second_scene, "R during active play reloads the scene")
	check(not paused, "active restart leaves scene unpaused")
	if current_scene != null:
		check(current_scene.get_node("GameplayMSD/Player1") != null, "restarted players spawn successfully")

	print("RESTART_PLAYTEST_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
