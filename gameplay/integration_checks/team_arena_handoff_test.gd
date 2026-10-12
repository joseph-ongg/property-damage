## Test *real* upstream arena scenes using Gameplay's existing player prefabs.
## This script is intentionally outside gameplay/tests/: it requires an
## upstream scene file that may not exist on the current Gameplay branch.
## Run in an isolated combined project; never edit upstream files in place.
## TEAM_ARENA_SCENE=res://gameplay/test_arena.tscn ...Godot --headless --path ...
##    --script res://gameplay/integration_checks/team_arena_handoff_test.gd
extends SceneTree

var failures: Array[String] = []
var blockers: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func step(n: int) -> void:
	for _i in n:
		await physics_frame

func pulse(key: String) -> void:
	Input.action_press(key)
	await step(2)
	Input.action_release(key)

func _run() -> void:
	var source_path: String = OS.get_environment("TEAM_ARENA_SCENE")
	if source_path.is_empty():
		push_error("Supply TEAM_ARENA_SCENE pointing to an actual team scene. No final arena exists in main.")
		quit(2)
		return
	var pack: PackedScene = load(source_path) as PackedScene
	if pack == null:
		push_error("No team arena at " + source_path)
		quit(2)
		return
	var external_arena: Node2D = pack.instantiate() as Node2D
	check(external_arena != null, "loaded the actual team-owned arena PackedScene")
	if external_arena == null:
		quit(2)
		return
	root.add_child(external_arena)
	var floor: StaticBody2D = external_arena.get_node_or_null("Floor") as StaticBody2D
	check(floor != null, "upstream floor is a real StaticBody2D")
	if floor == null:
		quit(2)
		return
	var floor_collider: CollisionShape2D = floor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	check(floor_collider != null and floor_collider.shape is RectangleShape2D, "upstream floor has a real rectangle collider")
	var floor_top: float = floor.global_position.y - (floor_collider.shape as RectangleShape2D).size.y * 0.5
	check(floor_top > 100.0 and floor_top < 800.0, "floor height is read from the upstream scene, not hard-coded to Gameplay's room")
	# Remove only the instantiated placeholder, not the source teammate .tscn.
	var placeholder: Node = external_arena.get_node_or_null("Player")
	if placeholder != null:
		external_arena.remove_child(placeholder)
		placeholder.queue_free()
	var grid := GameplayEthanMaterialGrid.new()
	grid.name = "MaterialGrid"
	grid.width = 64
	grid.height = 40
	var timer := Timer.new()
	timer.name = "TickTimer"
	grid.add_child(timer)
	external_arena.add_child(grid)
	var bridge := GameplayFireBridge.new()
	bridge.name = "FireBridge"
	bridge.grid_path = NodePath("../MaterialGrid")
	external_arena.add_child(bridge)
	var renderer := GameplayTeamMaterialRenderer.new()
	renderer.name = "TeamMaterialRenderer"
	renderer.grid_path = NodePath("../MaterialGrid")
	external_arena.add_child(renderer)
	var player_scene := load("res://gameplay/prefabs/gameplay_player.tscn") as PackedScene
	var p1 := player_scene.instantiate() as GameplayPlayer
	var p2 := player_scene.instantiate() as GameplayPlayer
	p1.name = "P1"
	p2.name = "P2"
	p1.player_index = 1
	p2.player_index = 2
	p1.enhanced_jumping = true
	p2.enhanced_jumping = true
	p1.platform_drop_enabled = true
	p2.platform_drop_enabled = true
	p1.dash_enabled = false
	p2.dash_enabled = false
	p1.fire_bridge_path = NodePath("../FireBridge")
	p2.fire_bridge_path = NodePath("../FireBridge")
	p1.position = Vector2(200, floor_top - 130)
	p2.position = Vector2(740, floor_top - 130)
	external_arena.add_child(p1)
	external_arena.add_child(p2)
	await step(110)
	# Gameplay's Angela-compatible 32x64 collision shape is shifted upward
	# relative to the visual node origin; do not treat sprite origin as body
	# center. Derive the correct feet from the actual collider geometry.
	var p1_shape: CollisionShape2D = p1.get_node("CollisionShape2D")
	var p2_shape: CollisionShape2D = p2.get_node("CollisionShape2D")
	check((p1_shape.shape as RectangleShape2D).size == Vector2(32, 64) and (p2_shape.shape as RectangleShape2D).size == Vector2(32, 64),
		"both Gameplay players retain Angela-compatible 32x64 colliders")
	var origin_y: float = floor_top - p1_shape.position.y - (p1_shape.shape as RectangleShape2D).size.y * 0.5
	check(absf(p1.global_position.y - origin_y) < 3.0 and absf(p2.global_position.y - origin_y) < 3.0,
		"both real Gameplay players stand on the upstream floor with the collider offset accounted for")
	check(p1.collision_layer == 2 and p2.collision_layer == 2 and p1.collision_mask == 1 and p2.collision_mask == 1,
		"players collide only with the upstream world layer 1 and pass through each other")
	check(bridge.grid() == grid and renderer._grid == grid,
		"Ethan material state, Spark bridge and Jackson-derived renderer share one node")
	var x1: float = p1.global_position.x
	var x2: float = p2.global_position.x
	Input.action_press("p1_right")
	Input.action_press("p2_left")
	await step(20)
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	await step(18)  # let ground friction settle before targeting single cells
	check(p1.global_position.x > x1 + 22.0 and p2.global_position.x < x2 - 22.0,
		"both players move independently on the upstream arena floor")
	# Confirm actual overlap/crossover, not just a collision-mask inspection.
	p1.global_position = Vector2(395, origin_y)
	p2.global_position = Vector2(565, origin_y)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.motor.reset()
	p2.motor.reset()
	Input.action_press("p1_right")
	Input.action_press("p2_left")
	await step(45)
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	await step(18)
	check(p1.global_position.x > p2.global_position.x,
		"players physically cross through one another in Angela's real arena")
	# Source arena doesn't contain a material map. Seed a single cell to test
	# the actual teammate grid interface; report missing room materials below.
	var target: Vector2 = p1.global_position + Vector2(34, 0)
	var cell: Vector2i = bridge.world_to_cell(target)
	check(grid.in_bounds(cell.x, cell.y), "upstream floor player casts within the material-grid bounds")
	check(grid.get_cell_material(cell.x,cell.y) == MaterialGrid.Materials.AIR,
		"team collision scene does not invent a flammable furniture/material map")
	grid.set_cell_material(cell.x,cell.y,MaterialGrid.Materials.WOOD)
	var notifications: Array[Vector2i] = []
	bridge.cell_ignited.connect(func(c: Vector2i): notifications.append(c))
	await pulse("p1_spark")
	check(grid.is_burning(cell.x,cell.y) and notifications.size() == 1,
		"P1 Spark ignites the explicitly seeded wood cell in Ethan's storage")
	# Walk to p2's facing-left material target and verify the other input.
	var target2: Vector2 = p2.global_position + Vector2(-34,0)
	var cell2: Vector2i = bridge.world_to_cell(target2)
	grid.set_cell_material(cell2.x,cell2.y,MaterialGrid.Materials.WOOD)
	await pulse("p2_spark")
	check(grid.is_burning(cell2.x,cell2.y) and notifications.size() == 2,
		"P2 directional Spark independently ignites its facing cell")
	# Two rising edges spaced apart test the *actual* double-jump motor.
	var grounded_y: float = p1.global_position.y
	await pulse("p1_jump")
	await step(9)
	var after_first: float = p1.global_position.y
	await pulse("p1_jump")
	await step(5)
	check(after_first < grounded_y - 12.0 and p1.global_position.y < after_first,
		"upstream arena supports P1's independent first/second jumps")
	var p2_start_y: float = p2.global_position.y
	await pulse("p2_jump")
	await step(9)
	var p2_first_y: float = p2.global_position.y
	await pulse("p2_jump")
	await step(5)
	check(p2_first_y < p2_start_y - 12.0 and p2.global_position.y < p2_first_y,
		"upstream arena supports P2's independent first/second jumps")
	# The real Angela scene only has a floor, not the complete team MSD arena.
	if external_arena.get_node_or_null("LeftWall") == null or external_arena.get_node_or_null("RightWall") == null:
		blockers.append("Source scene has no left/right world boundary bodies")
	if external_arena.get_node_or_null("BookshelfTop") == null or external_arena.get_node_or_null("TableTop") == null or external_arena.get_node_or_null("FridgeTop") == null:
		blockers.append("Source scene has no fridge/bookshelf/table one-way platforms")
	blockers.append("No upstream furniture MaterialGrid seed/map accompanies this arena")
	print("ARENA_SOURCE ",source_path)
	print("ARENA_FLOOR_TOP ",floor_top)
	for blocked in blockers:
		print("BLOCKER: ",blocked)
	print("TEAM_ARENA_HANDOFF_SUMMARY passed_failures=",failures.size()," upstream_blockers=",blockers.size())
	var screenshot: String = OS.get_environment("CAPTURE_TEAM_ARENA")
	if not screenshot.is_empty() and DisplayServer.get_name() != "headless":
		# The screenshot uses the *loaded teammate scene*, not our decorated
		# gameplay/msd/gameplay_msd.tscn test arena. Keep proof of scope.
		await process_frame
		RenderingServer.force_draw(false)
		var shot: Image = root.get_texture().get_image()
		var error: Error = shot.save_png(screenshot)
		check(error == OK, "captured Angela's scene with the attached Gameplay players and Ethan's active material grid")
		print("ARENA_SCREENSHOT ",screenshot," size=",shot.get_size())
	quit(0 if failures.is_empty() else 1)
