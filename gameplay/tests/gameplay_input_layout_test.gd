## Real input and HUD layout acceptance for the two-player MSD room.
## Down+Jump should never start a jump when drop-through is impossible.
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


func frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _run() -> void:
	var scene := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(65)
	var room: Node2D = scene.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var hud: CanvasLayer = room.get_node("HUD")
	check(p1.is_on_floor() and p2.is_on_floor(), "both players start on solid ground")

	var p1_start: float = p1.global_position.y
	var p2_start: float = p2.global_position.y
	Input.action_press("p1_down")
	Input.action_press("p2_down")
	Input.action_press("p1_jump")
	Input.action_press("p2_jump")
	await frames(5)
	Input.action_release("p1_jump")
	Input.action_release("p2_jump")
	Input.action_release("p1_down")
	Input.action_release("p2_down")
	check(absf(p1.global_position.y - p1_start) < 1.0 and p1.is_on_floor(), "S+W on solid floor does not accidentally jump P1")
	check(absf(p2.global_position.y - p2_start) < 1.0 and p2.is_on_floor(), "Down+Up on solid floor does not accidentally jump P2")
	check(p1.motor.jumps_remaining() == 2 and p2.motor.jumps_remaining() == 2, "failed drop attempts do not consume jump charges")
	await frames(3)
	Input.action_press("p1_jump")
	Input.action_press("p2_jump")
	await frames(5)
	Input.action_release("p1_jump")
	Input.action_release("p2_jump")
	check(p1.velocity.y < -100.0 and p2.velocity.y < -100.0, "W and Up still perform normal jumps after a failed drop")

	# All always-visible control text must stay within its assigned card.
	var left: Label = hud.get_node("Controls")
	var left_more: Label = hud.get_node("ControlsExtraP1")
	var right: Label = hud.get_node("ControlsP2")
	var right_more: Label = hud.get_node("ControlsExtraP2")
	var bottom: ColorRect = hud.get_node("BottomStrip")
	check(left.text.contains("S+W") and left_more.text.contains("F") and left_more.text.contains("G"), "P1 card covers move, jump, drop, Spark, use and magic")
	check(right.text.contains("DOWN+UP") and right_more.text.contains("ENTER") and right_more.text.contains("SHIFT"), "P2 card covers the actual independent keyboard actions")
	check(left.offset_left > 55 and left.offset_right < 480 and right.offset_left > 480 and right.offset_right < 960, "control cards occupy separate halves")
	check(left_more.offset_right <= 480 and right_more.offset_right <= 960, "secondary control rows stay within 960px screen")
	check(bottom.offset_top >= 499 and bottom.offset_bottom <= 540, "controls remain below the playable room floor")
	check(hud.get_node("SystemHint").text.contains("PAUSE") and hud.get_node("SystemHint").text.contains("RESTART"), "pause and restart keys are visible")
	check(hud.get_node("SparkStatus").offset_right <= 960, "status panel fits within the viewport")

	scene.queue_free()
	print("INPUT_LAYOUT_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
