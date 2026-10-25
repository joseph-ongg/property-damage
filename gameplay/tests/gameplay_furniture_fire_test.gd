## Furniture fuel is hidden until lit and uses the room's real MaterialGrid.
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


func _run() -> void:
	var scene: PackedScene = load("res://gameplay/msd/gameplay_msd.tscn")
	var room: Node2D = scene.instantiate()
	root.add_child(room)
	await physics_frame
	var grid: MaterialGrid = room.get_node("MaterialGrid")
	var layer: GameplayFurnitureFireLayer = room.get_node("MaterialGrid/FurnitureFireLayer")
	var renderer: GameplayTeamMaterialRenderer = room.get_node("TeamMaterialRenderer")
	var bridge: GameplayFireBridge = room.get_node("FireBridge")
	check(renderer._furniture_layer == layer, "renderer uses the room's furniture mask")
	for cell in [Vector2i(12, 19), Vector2i(12, 22), Vector2i(12, 28), Vector2i(29, 23), Vector2i(29, 25), Vector2i(24, 28), Vector2i(35, 28)]:
		check(layer.covers_cell(cell) and grid.get_cell_material(cell.x, cell.y) == MaterialGrid.Materials.WOOD, "furniture has flammable grid fuel at %s" % str(cell))
		check(not renderer.should_draw_cell(cell.x, cell.y), "unlit furniture material is invisible at %s" % str(cell))
	check(not layer.covers_cell(Vector2i(29, 28)) and grid.get_cell_material(29, 28) == MaterialGrid.Materials.AIR, "open space under tabletop is not fuel")
	check(not layer.covers_cell(Vector2i(40, 20)) and grid.get_cell_material(40, 20) == MaterialGrid.Materials.STONE, "AC remains outside furniture fuel")
	check(bridge.ignite_world(Vector2(200, 360)), "direct ignition uses existing fire bridge on bookshelf")
	check(grid.is_burning(12, 22) and renderer.should_draw_cell(12, 22), "lit bookshelf is visible through the existing renderer")
	grid.ignite(11, 24)
	check(grid.is_burning(11, 24) and renderer.should_draw_cell(11, 24), "Simulation ignite API directly lights bookshelf fuel")
	grid.wood_spread_chance = 1.0
	grid._spread_fire()
	check(grid.is_burning(13, 22), "simulation spreads fire to adjacent bookshelf cell")
	var bolt := GameplayMagicBolt.new()
	room.get_node("Projectiles").add_child(bolt)
	bolt.global_position = Vector2(350, 392)
	bolt.direction = 1
	var hits: Array[String] = []
	bolt.hit.connect(func(target_name: String, _caster_index: int): hits.append(target_name))
	for _i in 6:
		await physics_frame
	check(hits.has("TABLE") and grid.is_burning(23, 24), "moving fireball ignites table through the same grid API")
	check(renderer.should_draw_cell(23, 24), "fireball-lit table fire is visible")
	grid.ignite(24, 25)
	grid._spread_fire()
	check(grid.is_burning(24, 26), "simulation spreads tabletop fire into its leg")
	room.queue_free()
	print("FURNITURE_FIRE_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
