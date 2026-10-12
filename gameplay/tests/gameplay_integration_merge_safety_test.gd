## Upstream-safe Ethan adapter and same-tick Art action feedback.
## Run this unchanged both before and after merging Ethan's material_grid.gd.
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
	var game: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await frames(65)
	var arena: Node2D = game.get_node("GameplayMSD")
	var grid: GameplayEthanMaterialGrid = arena.get_node("MaterialGrid")
	var bridge: GameplayFireBridge = arena.get_node("FireBridge")
	var renderer: GameplayTeamMaterialRenderer = arena.get_node("TeamMaterialRenderer")
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	check(grid != null and grid is MaterialGrid and bridge.grid() == grid, "Ethan adapter retains MaterialGrid type and Gameplay bridge")
	check(renderer._grid == grid, "Jackson renderer reads the same active upstream/fallback grid")
	# Detect the actual parent implementation rather than assuming main's
	# scaffold or a permanently separate Gameplay storage exists.
	var upstream_properties: Dictionary = {}
	for info: Dictionary in grid.get_property_list():
		if info.name in ["materials", "burning", "burn_timers"]:
			upstream_properties[info.name] = true
	check(grid.using_upstream_storage() == (upstream_properties.size() == 3), "adapter selects upstream storage based on the parent properties")
	if grid.using_upstream_storage():
		check(grid._fallback_materials.is_empty() and grid._fallback_burning.is_empty(), "official Ethan merge uses no duplicate Gameplay fire arrays")
		check(grid.get("materials").size() == grid.width, "official Ethan parent actually holds material columns")
	else:
		check(grid._fallback_materials.size() == grid.width and grid._fallback_burning.size() == grid.width, "pre-merge main uses the existing Ethan algorithm through private fallback arrays")
	var cell: Vector2i = bridge.world_to_cell(Vector2(400, 478))
	var events: Array[Vector2i] = []
	bridge.cell_ignited.connect(func(c: Vector2i): events.append(c))
	check(bridge.ignite_world(Vector2(400, 478)) and grid.is_burning(cell.x, cell.y), "Spark ignites real active storage")
	check(events.size() == 1, "one first-ignite notification with no duplicate signals")
	check(bridge.ignite_world(Vector2(400, 478)) and events.size() == 1, "casting again does not report false extra first-ignite")
	grid.extinguish(cell.x, cell.y)
	check(not grid.is_burning(cell.x, cell.y) and is_zero_approx(grid.cell_burn_timer(cell.x, cell.y)), "active fire timer is cleared after extinguish")

	# Both player sprites must switch during the same movement tick as their
	# physical keyboard action and remain in the second pose briefly.
	check(p1.sprite.texture == GameplayPlayer.MAGE1 and p2.sprite.texture == GameplayPlayer.MAGE2, "P1/P2 begin on source Art Team static poses")
	Input.action_press("p1_interact")
	Input.action_press("p2_interact")
	await frames(1)
	# SceneTree.physics_frame is emitted *before* child _physics_process.
	# Inspect at the following render frame, after that physics step completes.
	await process_frame
	check(p1.sprite.texture == GameplayPlayer.MAGE1_ACTION and p2.sprite.texture == GameplayPlayer.MAGE2_ACTION, "both interaction sprites respond during the first completed physics step")
	Input.action_release("p1_interact")
	Input.action_release("p2_interact")
	await frames(19)
	check(p1.sprite.texture == GameplayPlayer.MAGE1 and p2.sprite.texture == GameplayPlayer.MAGE2, "the action-pose timer restores static frames")
	# Separate paths for Spark and magic must also show the same source pose.
	Input.action_press("p1_spark")
	Input.action_press("p2_attack")
	await frames(1)
	await process_frame
	check(p1.sprite.texture == GameplayPlayer.MAGE1_ACTION, "P1 Spark switches to Art Team casting pose in the first completed step")
	check(p2.sprite.texture == GameplayPlayer.MAGE2_ACTION, "P2 magic attack switches to red casting pose in the first completed step")
	Input.action_release("p1_spark")
	Input.action_release("p2_attack")
	await frames(19)
	game.queue_free()
	print("INTEGRATION_MERGE_SAFETY_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
