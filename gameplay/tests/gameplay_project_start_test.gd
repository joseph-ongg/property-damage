## F5 opens level selection, then its Living Room button launches the arena.
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


func _run() -> void:
	var startup: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	check(startup == "res://gameplay/level_select.tscn", "F5 starts on level selection")
	var scene: PackedScene = load(startup)
	check(scene != null, "configured F5 launch scene loads")
	if scene == null:
		quit(1)
		return
	var instance: Control = scene.instantiate()
	root.add_child(instance)
	current_scene = instance
	check(instance.get_node_or_null("LivingRoomButton") != null, "level selection offers Living Room")
	check(instance.get_node_or_null("GardenButton") != null, "level selection offers Garden")
	(instance.get_node("LivingRoomButton") as Button).pressed.emit()
	for _i in 65:
		await physics_frame
	var arena: Node2D = current_scene.get_node_or_null("GameplayMSD")
	check(arena != null, "Living Room selection launches the two-player gameplay arena")
	if arena != null:
		var p1: GameplayPlayer = arena.get_node("Player1")
		var p2: GameplayPlayer = arena.get_node("Player2")
		check(p1 != null and p2 != null, "F5 scene has both independent player controllers")
		check(p1.is_on_floor() and p2.is_on_floor(), "both players spawn safely on the arena floor")
		var grid: MaterialGrid = arena.get_node("MaterialGrid")
		var bridge: GameplayFireBridge = arena.get_node("FireBridge")
		check(bridge.grid() == grid, "F5 scene connects Spark to the active test material grid")
		check(arena.get_node("HUD/Controls") != null and arena.get_node("HUD/ControlsP2") != null, "F5 scene shows both control guides")
	current_scene.queue_free()
	print("PROJECT_START_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
