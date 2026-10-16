## Use real physical-key events, not direct action injection, to guard
## against modifier keys stealing the other player's movement inputs.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func key_event(code: Key, pressed: bool, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.shift_pressed = shift
	Input.parse_input_event(event)
	# In headless Godot the synthetic physical-key event can otherwise remain
	# buffered until the next unrelated frame; flush before measuring movement.
	Input.flush_buffered_events()


func frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _run() -> void:
	var scene: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(65)
	var p1: GameplayPlayer = scene.get_node("GameplayMSD/Player1")
	var p2: GameplayPlayer = scene.get_node("GameplayMSD/Player2")
	check(InputMap.has_action("p1_jump") and InputMap.has_action("p2_interact"), "both players register their physical key bindings")

	# P2 uses Shift for interaction, but holding Shift must not block P1 W.
	key_event(KEY_SHIFT, true)
	await frames(2)
	check(Input.is_action_pressed("p2_interact"), "physical Shift maps to P2 interaction")
	var initial_y := p1.global_position.y
	key_event(KEY_W, true, true)
	await frames(3)
	check(Input.is_action_pressed("p1_jump"), "Shift+W still maps to P1 jump")
	check(p1.global_position.y < initial_y - 2.0 and p1.velocity.y < -100.0, "P1 jumps while P2 holds Shift")
	key_event(KEY_W, false, true)
	key_event(KEY_SHIFT, false)
	await frames(3)
	check(not Input.is_action_pressed("p2_interact"), "P2 interaction releases without affecting P1")

	# Hold both players' left/right directions simultaneously with raw keys.
	var p1_x := p1.global_position.x
	var p2_x := p2.global_position.x
	key_event(KEY_D, true)
	key_event(KEY_LEFT, true)
	await frames(12)
	key_event(KEY_D, false)
	key_event(KEY_LEFT, false)
	check(p1.global_position.x > p1_x + 3.0 and p1.velocity.x > 0.0, "physical D steers airborne P1 right")
	check(p2.global_position.x < p2_x - 12.0 and p2.velocity.x < -100.0, "physical Left arrow simultaneously moves P2 left")
	check(p1.facing == 1 and p2.facing == -1, "independent direction states survive simultaneous keys")

	# Raw input preserves separate Spark hotkeys and cooldowns.
	key_event(KEY_F, true)
	key_event(KEY_ENTER, true)
	await frames(3)
	key_event(KEY_F, false)
	key_event(KEY_ENTER, false)
	check(not p1.spark.is_ready() and not p2.spark.is_ready(), "physical F and Enter activate independent Spark cooldowns")

	scene.queue_free()
	print("KEYBOARD_CHORDS_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
