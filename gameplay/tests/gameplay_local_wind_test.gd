extends SceneTree

class TestWindSource:
	extends RefCounted

	var active: bool = false
	var direction: Vector2 = Vector2.RIGHT
	var bounds: Rect2 = Rect2(100, 100, 100, 100)

	func simulation_wind_is_active() -> bool:
		return active

	func simulation_wind_direction() -> Vector2:
		return direction

	func simulation_wind_contains(world_point: Vector2) -> bool:
		return bounds.has_point(world_point)


class TestWindNode:
	extends Node

	var bounds: Rect2 = Rect2(300, 300, 50, 50)

	func simulation_wind_is_active() -> bool:
		return true

	func simulation_wind_direction() -> Vector2:
		return Vector2.LEFT

	func simulation_wind_contains(world_point: Vector2) -> bool:
		return bounds.has_point(world_point)


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
	var source := TestWindSource.new()
	source.bounds = Rect2(100, 100, 100, 100)
	source.active = false
	WindModel.register_wind_source(source)

	check(not bool(WindModel.wind_at(Vector2(150, 150)).active),
		"no active wind source")
	source.active = true
	check(bool(WindModel.wind_at(Vector2(150, 150)).active),
		"enabled source covers candidate center")
	check(not bool(WindModel.wind_at(Vector2(250, 250)).active),
		"out-of-range candidate ignores local source")
	source.active = false

	var model_grid := MaterialGrid.new()
	model_grid.name = "DeterministicWindGrid"
	model_grid.width = 20
	model_grid.height = 20
	model_grid.cell_size = 16
	model_grid.wind_direction = Vector2.ZERO
	model_grid.wind_strength = 0.0
	model_grid.local_fire_wind_strength = 0.5
	model_grid.position = Vector2.ZERO
	var tick_timer := Timer.new()
	tick_timer.name = "TickTimer"
	model_grid.add_child(tick_timer)
	root.add_child(model_grid)

	var no_wind := model_grid.adjusted_fire_spread_chance(
		0.20, 10, 10, 11, 10
	)
	check(is_equal_approx(no_wind, 0.20),
		"source-free spread remains unchanged")

	source.direction = Vector2.RIGHT
	source.active = true
	source.bounds = Rect2(100, 100, 10, 10)
	var downwind := model_grid.adjusted_fire_spread_chance(
		0.20, 6, 6, 7, 6
	)
	check(is_equal_approx(downwind, 0.20),
		"source outside candidate keeps existing probability")

	source.bounds = Rect2(104, 96, 104, 32)
	downwind = model_grid.adjusted_fire_spread_chance(
		0.20, 6, 6, 7, 6
	)
	check(is_equal_approx(downwind, 0.30),
		"downwind candidate increases spread probability")
	var upwind := model_grid.adjusted_fire_spread_chance(
		0.20, 7, 6, 6, 6
	)
	check(is_equal_approx(upwind, 0.10),
		"upwind candidate decreases spread probability")

	model_grid.wind_direction = Vector2.RIGHT
	model_grid.wind_strength = 0.5
	source.direction = Vector2.RIGHT
	var combined := model_grid.adjusted_fire_spread_chance(
		0.20, 6, 6, 7, 6
	)
	check(is_equal_approx(combined, 0.45),
		"global and local rightward wind combine")
	source.direction = Vector2.LEFT
	var opposed := model_grid.adjusted_fire_spread_chance(
		0.20, 6, 6, 7, 6
	)
	check(is_equal_approx(opposed, 0.15),
		"local wind opposes global wind predictably")

	WindModel.unregister_wind_source(source)

	var living_scene: PackedScene = load("res://gameplay/playtest_main.tscn")
	var living_instance := living_scene.instantiate()
	root.add_child(living_instance)
	await physics_frame
	await physics_frame
	var room: Node2D = living_instance.get_node("GameplayMSD")
	var fan: GameplayAppliance = room.get_node("Appliances/FanDevice")
	var ac: GameplayAppliance = room.get_node("Appliances/ACDevice")
	var grid: Node2D = room.get_node("MaterialGrid")

	check(WindModel.wind_at(
		fan.global_position + Vector2(-36, 89)
	).active == false,
		"Living Room fan starts off")
	fan.set_fan_power(true)
	check(WindModel.wind_at(
		fan.global_position + Vector2(-36, 89)
	).active == false,
		"Living Room fan on without plug does not blow fire")
	fan.fan_plugged_in = true
	var fan_inside := fan.global_position + Vector2(-36, 89)
	check(bool(WindModel.wind_at(fan_inside).active),
		"Living Room fan is discovered and active in downwind area")
	check(not bool(WindModel.wind_at(
		fan.global_position + Vector2(36, 89)
	).active),
		"Living Room fan is inactive behind its face")

	ac.switched_on = true
	check(bool(WindModel.wind_at(ac.global_position).active),
		"Living Room AC source uses switched-on plus adapter default")
	ac.switched_on = false
	check(not bool(WindModel.wind_at(ac.global_position).active),
		"Living Room AC off removes its local wind")

	check(WindModel.wind_at(
		fan.global_position + Vector2(-fan.effect_radius - 2, 89)
	).active == false,
		"Living Room fan range outside leaves spread wind-free")
	var fan_cell: Vector2i = grid.world_to_cell(fan_inside)
	fan.fan_plugged_in = false
	fan.set_fan_power(false)
	var fan_off_chance: float = grid.adjusted_fire_spread_chance(
		0.20, fan_cell.x + 1, fan_cell.y, fan_cell.x, fan_cell.y
	)
	check(is_equal_approx(fan_off_chance, 0.20),
		"Living Room fan-off leaves in-area spread probability unchanged")
	fan.fan_plugged_in = true
	fan.set_fan_power(true)
	var fan_on_chance: float = grid.adjusted_fire_spread_chance(
		0.20, fan_cell.x + 1, fan_cell.y, fan_cell.x, fan_cell.y
	)
	check(is_equal_approx(fan_on_chance, 0.27),
		"Living Room fan on and plugged adjusts in-area spread probability")
	check(grid is GameplayEthanMaterialGrid,
		"real Living Room scene uses the Gameplay/Ethan MaterialGrid")
	check(WindModel.registered_wind_source_count() == 2,
		"Living Room registry contains only Fan and AC")
	WindModel.register_wind_source(fan)
	WindModel.register_wind_source(fan)
	WindModel.register_wind_source(ac)
	check(WindModel.registered_wind_source_count() == 2,
		"duplicate Fan and AC registration does not add entries")

	room.experimental_appliances_enabled = false
	await physics_frame
	check(not bool(WindModel.wind_at(fan_inside).active),
		"appliance master off disables Fan fire wind")
	check(not bool(WindModel.wind_at(ac.global_position).active),
		"appliance master off disables AC fire wind")
	room.experimental_appliances_enabled = true
	await physics_frame
	check(bool(WindModel.wind_at(fan_inside).active),
		"appliance master re-enable restores Fan fire wind")
	ac.switched_on = true
	check(bool(WindModel.wind_at(ac.global_position).active),
		"appliance master re-enable restores AC fire wind")

	var doomed := TestWindNode.new()
	root.add_child(doomed)
	WindModel.register_wind_source(doomed)
	check(WindModel.registered_wind_source_count() == 3,
		"destroyable wind source can be registered")
	doomed.queue_free()
	await physics_frame
	await physics_frame
	check(WindModel.registered_wind_source_count() == 2,
		"freed wind source is removed from the registry")

	model_grid.queue_free()
	living_instance.queue_free()
	await physics_frame
	await physics_frame
	check(WindModel.registered_wind_source_count() == 0,
		"scene reload/unload leaves no old Fan or AC wind source")
	print("LOCAL_WIND_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
