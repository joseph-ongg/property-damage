## F5 project launcher regression: the selected startup must be the playable
## independent co-op room, not the team-owned placeholder in root main.tscn.
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
	check(startup == "res://gameplay/playtest_main.tscn", "F5 starts the playable Gameplay scene rather than the placeholder")
	var scene: PackedScene = load(startup)
	check(scene != null, "configured F5 launch scene loads")
	if scene == null:
		quit(1)
		return
	var instance: Node2D = scene.instantiate()
	root.add_child(instance)
	for _i in 65:
		await physics_frame
	var arena: Node2D = instance.get_node_or_null("GameplayMSD")
	check(arena != null, "F5 launches the two-player gameplay arena")
	if arena != null:
		var p1: GameplayPlayer = arena.get_node("Player1")
		var p2: GameplayPlayer = arena.get_node("Player2")
		check(p1 != null and p2 != null, "F5 scene has both independent player controllers")
		check(p1.is_on_floor() and p2.is_on_floor(), "both players spawn safely on the arena floor")
		var grid: MaterialGrid = arena.get_node("MaterialGrid")
		var bridge: GameplayFireBridge = arena.get_node("FireBridge")
		check(bridge.grid() == grid, "F5 scene connects Spark to the active test material grid")
		check(arena.get_node("HUD/Controls") != null and arena.get_node("HUD/ControlsP2") != null, "F5 scene shows both control guides")
	instance.queue_free()
	print("PROJECT_START_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
