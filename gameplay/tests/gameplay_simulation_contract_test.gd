## Exercise the Gameplay fire bridge against whichever Simulation-owned grid is installed.
## Main's unimplemented scaffold should fail safely; Ethan's storage should ignite wood.
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
	var stage := Node2D.new()
	stage.name = "SimulationContractTest"
	root.add_child(stage)
	var upstream: MaterialGrid = MaterialGrid.new()
	upstream.name = "UpstreamGrid"
	upstream.add_child(Timer.new())
	upstream.get_child(0).name = "TickTimer"
	stage.add_child(upstream)
	var bridge := GameplayFireBridge.new()
	bridge.name = "Bridge"
	bridge.grid_path = NodePath("../UpstreamGrid")
	stage.add_child(bridge)
	await physics_frame
	await physics_frame
	check(upstream.get_script().resource_path == "res://onboarding/burn-box/material_grid.gd", "real Simulation module keeps its own script path")
	check(upstream.has_method("ignite") and upstream.has_method("is_burning") and upstream.has_method("world_to_cell"), "Simulation public functions are available")
	var point := Vector2(39, 27)
	var cell := Vector2i(2, 1)
	check(bridge.world_to_cell(point) == cell, "bridge uses Simulation coordinate conversion")
	check(not bridge.ignite_world(point), "unpainted air never reports ignition")
	upstream.set_cell_material(cell.x, cell.y, MaterialGrid.Materials.WOOD)
	var has_storage := upstream.get_cell_material(cell.x, cell.y) == MaterialGrid.Materials.WOOD
	var ignition_events: Array[Vector2i] = []
	bridge.cell_ignited.connect(func(hit: Vector2i): ignition_events.append(hit))
	var ignited := bridge.ignite_world(point)
	check(ignited == has_storage, "bridge reports fire only when the installed Simulation storage supports it")
	check(bridge.is_burning_world(point) == has_storage, "bridge reads the installed Simulation burning state")
	check(ignition_events.size() == (1 if has_storage else 0), "real ignition emits one event; unfinished scaffold emits none")
	if has_storage:
		check(ignition_events[0] == cell and bridge.ignite_world(point) and ignition_events.size() == 1, "Ethan grid supports repeated sparks without duplicate first-ignite events")
	else:
		check(not bridge.ignite_world(point), "main scaffold never produces false-positive sparks")

	var demo := GameplayDemoMaterialGrid.new()
	demo.name = "IsolatedDemoGrid"
	demo.add_child(Timer.new())
	demo.get_child(0).name = "TickTimer"
	stage.add_child(demo)
	demo.set_cell_material(cell.x, cell.y, MaterialGrid.Materials.WOOD)
	check(demo.get_cell_material(cell.x, cell.y) == MaterialGrid.Materials.WOOD, "Gameplay's temporary grid stores its own material")
	check(not demo.is_burning(cell.x, cell.y), "Gameplay demo starts unburned regardless of upstream state")
	demo.ignite(cell.x, cell.y)
	check(demo.is_burning(cell.x, cell.y), "Gameplay demo lights wood independently of upstream implementation")
	check(upstream.is_burning(cell.x, cell.y) == has_storage, "demo storage does not write into Simulation-owned grid")

	stage.queue_free()
	print("SIMULATION_CONTRACT_SUMMARY upstream_storage=", has_storage, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
