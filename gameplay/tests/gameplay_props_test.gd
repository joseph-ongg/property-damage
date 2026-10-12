## Explicitly experimental property response; not a win condition or fire storage.
extends SceneTree

var failed: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(value: bool, reason: String) -> void:
	if value:
		print("PASS: ", reason)
	else:
		failed.append(reason)
		push_error("FAIL: " + reason)


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	var root_scene := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(root_scene)
	await frames(65)
	var room := root_scene.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var prop: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	var top: GameplayBurnableProp = room.get_node("Books/TableBooks")
	check(room.experimental_books_enabled, "book response explicitly opt-in as experimental")
	check(not prop.scorched and not top.scorched, "books start visually intact")
	check(not prop.try_scorch(Vector2(-100, -100), 1), "distant sparks do not damage books")
	check(not prop.scorched, "missed sparks leave books intact")
	# Spark comes from a normal player Input action, not a shortcut test method.
	p1.global_position = Vector2(309, 477)
	p1.velocity = Vector2.ZERO
	p1.facing = 1
	p1.spark._cooldown_remaining = 0.0
	await frames(3)
	Input.action_press("p1_spark")
	await frames(3)
	Input.action_release("p1_spark")
	check(prop.scorched, "P1's actual spark changes nearby book appearance")
	check(prop.flash_left > 0.0, "book scorches produce brief ember feedback")
	check(not top.scorched, "unrelated books are unchanged")
	check(room.status_text.text.contains("VISUAL TEST"), "HUD distinguishes mock prop feedback from Simulation")
	check(not prop.try_scorch(prop.global_position, 2), "book cannot repeatedly reward a scorch")
	await frames(95)
	check(prop.scorched and prop.flash_left == 0.0, "book remains charred when transient embers expire")
	# Missing Simulation shouldn't cause the visual prototype to crash.
	room.get_node("FireBridge").grid_path = NodePath("../UnavailableMaterialGrid")
	check(top.try_scorch(top.global_position, 2), "visual prop logic does not depend on Simulation storage")
	check(not room.get_node("VictoryOverlay") if room.has_node("VictoryOverlay") else true, "property interaction adds no made-up victory condition")
	root_scene.queue_free()
	print("GAMEPLAY_PROPS_SUMMARY failures=", failed.size())
	quit(0 if failed.is_empty() else 1)
