## Checks actual Gameplay room HUD/input feedback and nearby player prompts.
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

func _run() -> void:
	var root_scene: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(root_scene)
	await frames(65)
	var arena: Node2D = root_scene.get_node("GameplayMSD")
	var hud: CanvasLayer = arena.get_node("HUD")
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	var hints: Node2D = arena.get_node("InteractionHints")
	var fridge: GameplayAppliance = arena.get_node("Appliances/FridgeDevice")
	check(p1.tint.b > p1.tint.g and p1.tint.g > p1.tint.r, "P1 HUD/FX uses blue palette matching blue Art Team character")
	check(p2.tint.r > p2.tint.b and p2.tint.r > p2.tint.g, "P2 uses contrasting red palette")
	check("PROTOTYPE" in (hud.get_node("Subtitle") as Label).text, "compact HUD still identifies the unfinished prototype")
	check("P1 F" in (hud.get_node("SparkStatus") as Label).text, "Spark status identifies P1 button")
	for node_name in ["Controls", "ControlsExtraP1", "ControlsP2", "ControlsExtraP2"]:
		var label: Label = hud.get_node(node_name)
		var font: Font = label.get_theme_font("font")
		var width: float = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		check(width < label.offset_right - label.offset_left, node_name + " compact controls fit the 960px game HUD")
	# With both players near the same fridge, each must get a legible prompt
	# and the two panels must stay within the playing area without overlapping.
	p1.global_position = Vector2(761, 478)
	p2.global_position = Vector2(792, 478)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.motor.reset()
	p2.motor.reset()
	await frames(4)
	var panels: Array[Dictionary] = hints.prompt_layouts()
	check(panels.size() == 2, "two players simultaneously receive separate interaction prompts")
	if panels.size() == 2:
		var a: Rect2 = panels[0]["rect"]
		var b: Rect2 = panels[1]["rect"]
		check(not a.intersects(b), "P1 and P2 prompt panels don't overlap")
		check(a.position.y >= 73.0 and b.position.y >= 73.0 and a.end.y <= 500.0 and b.end.y <= 500.0,
			"prompts stay between upper/lower HUD bands")
		check(str(panels[0]["text"]).contains("OPEN FRIDGE") and str(panels[1]["text"]).contains("OPEN FRIDGE"),
			"both real prompts match the same unopened fridge state")
	check(not fridge.switched_on, "fridge begins closed")
	Input.action_press("p2_interact")
	await frames(2)
	Input.action_release("p2_interact")
	check(fridge.switched_on, "P2 physically opens the fridge via SHIFT")
	check("FRIDGE OPEN" in (hud.get_node("SparkStatus") as Label).text,
		"feedback says FRIDGE OPEN, not refrigerator ON")
	check("CLOSE FRIDGE" in hints.hint_for(p2), "nearby prompt changes to CLOSE FRIDGE")
	await frames(3)
	Input.action_press("p2_interact")
	await frames(2)
	Input.action_release("p2_interact")
	check(not fridge.switched_on and "FRIDGE CLOSED" in (hud.get_node("SparkStatus") as Label).text,
		"second SHIFT actually closes fridge and reports CLOSED")
	root_scene.queue_free()
	print("INTERACTION_POLISH_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
