## Accept Design's furniture/material geometry + Ethan's real storage algorithm
## + Jackson palette renderer + Art's second static casting pose in the MSD room.
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
	var inst: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	await frames(65)
	var room: Node2D = inst.get_node("GameplayMSD")
	var grid: GameplayEthanMaterialGrid = room.get_node("MaterialGrid")
	var material_render: GameplayTeamMaterialRenderer = room.get_node("TeamMaterialRenderer")
	var bridge: GameplayFireBridge = room.get_node("FireBridge")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	check(grid != null and grid.get_script().resource_path == "res://gameplay/integration/ethan_material_grid.gd", "default room uses Ethan's real storage methods rather than demo subclass")
	if grid.using_upstream_storage():
		check(grid.get("materials").size() == grid.width and grid.get("burning").size() == grid.width and grid.get("burn_timers").size() == grid.width, "merged Ethan parent provides official material, fire, and timer arrays")
		check(grid._fallback_materials.is_empty() and grid._fallback_burning.is_empty(), "no redundant fallback storage when official Ethan arrays exist")
	else:
		check(grid._fallback_materials.size() == grid.width and grid._fallback_burning.size() == grid.width and grid._fallback_burn_timers.size() == grid.width, "pre-merge Ethan adapter stores materials, fire and timer arrays")
	check(material_render._grid == grid and room.get_node("FireVisuals")._grid == grid and bridge.grid() == grid, "gameplay, renderer, FX and bridge all use one grid instance")
	check(material_render.z_index < p1.z_index and material_render.z_index > room.get_node("RoomVisuals").z_index, "Jackson's pixel overlay is above art backdrop and below characters")
	check(material_render.COLORS[MaterialGrid.Materials.WOOD].is_equal_approx(Color(0.395, 0.167, 0.086, 1.0)), "wood tint comes from Jackson's real material palette")
	check(material_render.COLORS[MaterialGrid.Materials.WATER].is_equal_approx(Color(0.0, 0.435, 0.945, 1.0)), "water tint comes from Jackson's real palette")
	check(material_render.material_opacity < 0.40 and material_render.fire_opacity < 0.8, "material preview does not paint opaque full-grid panels over Art Team scene")
	var changed: int = material_render.refresh_count
	grid.set_cell_material(12, 13, MaterialGrid.Materials.OIL)
	check(material_render.refresh_count > changed, "Jackson's material layer redraws on upstream material-change signal")
	check(grid.get_cell_material(12, 13) == MaterialGrid.Materials.OIL, "Ethan-compatible storage returns OIL through the official API")
	check(bridge.ignite_world(Vector2(200, 216)), "Ethan's real OIL storage ignites via Gameplay bridge")
	check(grid.is_burning(12, 13) and material_render.refresh_count >= changed+2, "ignition is stored by Ethan and signaled to the renderer")
	grid.extinguish(12,13)
	check(not grid.is_burning(12, 13) and is_zero_approx(grid.cell_burn_timer(12, 13)), "Ethan extinguish resets the active burn timer")
	grid.set_cell_material(12,13,MaterialGrid.Materials.WATER)
	check(not bridge.ignite_world(Vector2(200,216)), "Ethan's real WATER cell cannot ignite")
	# Restore the non-gameplay test cell to AIR to avoid affecting later interactions.
	grid.set_cell_material(12,13,MaterialGrid.Materials.AIR)
	check(grid.get_cell_material(29,23) == MaterialGrid.Materials.WOOD, "Design desk material includes player's spark row above the tabletop")
	check(grid.get_cell_material(29,25) == MaterialGrid.Materials.WOOD, "Design desk material includes its physical surface row")
	check(grid.get_cell_material(16,31) == MaterialGrid.Materials.WOOD, "the visual wood floor reaches the collision boundary")
	check(grid.get_cell_material(48,31) == MaterialGrid.Materials.STONE, "fridge foundation remains nonflammable despite wood floor")
	check(grid.get_cell_material(40,20) == MaterialGrid.Materials.STONE, "Design's wall-mounted AC has nonflammable housing")
	check(room.get_node("BookshelfTop").position == Vector2(238,344) and room.get_node("TableTop").position == Vector2(485,411), "Design layout preserves the tested one-way platforms")

	var first_pose: Texture2D = GameplayPlayer.MAGE1_ACTION
	var red_pose: Texture2D = GameplayPlayer.MAGE2_ACTION
	check(first_pose.get_size() == Vector2(736,736) and red_pose.get_size() == Vector2(736,736), "both Art Team second-static poses retain the original 736px resolution")
	check(first_pose.get_image().get_data() != GameplayPlayer.MAGE1.get_image().get_data(), "PPT second static pose differs from idle still")
	check(red_pose.get_image().get_data() != first_pose.get_image().get_data(), "P2's action pose is recolored from the identical P1 image")
	check(p1.sprite.texture == GameplayPlayer.MAGE1 and p2.sprite.texture == GameplayPlayer.MAGE2, "characters begin with the original Art Team idle stills")
	Input.action_press("p1_interact")
	Input.action_press("p2_interact")
	await frames(3)
	Input.action_release("p1_interact")
	Input.action_release("p2_interact")
	check(p1.sprite.texture == first_pose and p2.sprite.texture == red_pose, "both actual gameplay interactions display the PPT second pose")
	await frames(22)
	check(p1.sprite.texture == GameplayPlayer.MAGE1 and p2.sprite.texture == GameplayPlayer.MAGE2, "action pose expires back to original static frames")
	inst.queue_free()
	print("TEAM_INTEGRATION_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
