extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error("FAIL: " + label)
	else:
		print("PASS: ", label)


func _run() -> void:
	var room: Node2D = (load("res://gameplay/msd/gameplay_msd.tscn") as PackedScene).instantiate()
	root.add_child(room)
	await physics_frame
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var book: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	var clock: GameplayWorldItem = room.get_node("WorldItems/Clock")
	var fan: GameplayAppliance = room.get_node("Appliances/FanDevice")
	var pc: GameplayAppliance = room.get_node("Appliances/ComputerDevice")
	check(book.has_tag("flammable") and book.has_tag("throwable") and not book.has_tag("fragile") and book.max_hp == 5.0, "books have reusable tags and five HP")
	check(clock.has_tag("fragile") and clock.max_hp == 10.0 and fan.max_hp == 20.0 and pc.max_hp == 15.0, "clock and appliances use configured durability")
	check((room.get_node("WorldItems/Outlet") as GameplayWorldItem).max_hp == INF, "outlet has infinite durability")
	check(InputMap.has_action("p1_carry") and InputMap.has_action("p2_carry"), "carry actions are distinct from interaction")
	p1.global_position = book.global_position + Vector2(-12, 0)
	(room.get_node("WorldItems/Plushie") as GameplayWorldItem).global_position = Vector2(600, 480)
	check(not room.get_carry_offer(p1).is_empty(), "book appears in carry offers")
	check(room.get_interaction_offer(p1).get("kind", "") != "pick", "interact never picks up books")
	room._on_carry(1, p1)
	check(book.carried_by == p1, "carry button picks up book")
	room._on_carry(1, p1)
	check(book.flying and book.carried_by == null, "carry button throws held book")
	var before_hp := clock.hp
	clock.take_damage(1.0, 1)
	check(clock.hp == before_hp - 1.0, "one attack consumes one item HP")
	var attack_before := p1.attack_damage
	clock.take_damage(clock.hp, 1)
	check(p1.attack_damage > attack_before and clock.destroyed_item, "destroying an item grants five percent attack damage")
	var plant: GameplayWorldItem = room.get_node("WorldItems/Plant")
	var bridge: GameplayFireBridge = room.get_node("FireBridge")
	check(bridge.ignite_world(plant.global_position), "flammable plant footprint is seeded into fire grid")
	plant._process(0.01)
	var plant_before := plant.hp
	plant._process(3.0)
	check(plant.burning and plant.hp == plant_before - 1.0, "grid fire burns one item HP every three seconds")
	plant._process(7.0)
	check(not plant.burning, "item flame extinguishes after ten seconds")
	var ash_sample := GameplayInteractableItem.new()
	room.add_child(ash_sample)
	ash_sample.hp = 1.0
	ash_sample.ignite()
	ash_sample._process(3.0)
	check(ash_sample.burned_to_ash and GameplayInteractableItem.BURNING_SPRITE != null and GameplayInteractableItem.ASHES_SPRITE != null, "burned item reaches ash state with both placeholder sprites loaded")
	p1.global_position = Vector2(100, 459)
	p2.global_position = Vector2(230, 459)
	var blocker: GameplayWorldItem = room.get_node("WorldItems/Plushie")
	blocker.global_position = Vector2(160, 450)
	var bolt := GameplayMagicBolt.new()
	room.get_node("Projectiles").add_child(bolt)
	bolt.caster_index = 1
	var player_before := p2.health
	var blocker_before := blocker.hp
	var hit_name: String = bolt._hit_combat_target(room, Vector2(110, 450), Vector2(240, 450))
	check(hit_name == "PLUSHIE" and blocker.hp == blocker_before - 1.0 and p2.health == player_before, "item between players absorbs a shot")
	var microwave: GameplayWorldItem = room.get_node("WorldItems/Microwave")
	p1.health = 10.0
	p1.global_position = microwave.interaction_point() + Vector2(0, 15)
	check(microwave.interact(p1) and microwave.opened, "microwave door opens")
	microwave.toggle_microwave_power()
	microwave.toggle_microwave_power()
	microwave._process(10.0)
	check(microwave.warm and not microwave.powered, "ten seconds of cooking warms nuggets")
	microwave.interact(p1)
	microwave.interact(p1)
	check(p1.health == 60.0 and microwave.contents == 2, "warm nugget restores fifty HP")
	var plant_fragile: GameplayWorldItem = room.get_node("WorldItems/Plant")
	plant_fragile._break_from_throw()
	check(plant_fragile.destroyed_item and not plant_fragile.can_pick_up(p1), "fragile plant breaks after a throw and cannot be carried again")
	var shards_victim_health := p2.health
	p2.global_position = plant_fragile.global_position
	plant_fragile._process(0.01)
	check(p2.health == shards_victim_health - 5.0, "stepping on plant shards deals five HP")
	var food: GameplayWorldItem = room.get_node("WorldItems/Food")
	check(food.has_tag("throwable") and food.max_hp == 1.0, "fridge food is throwable with one HP")
	blocker.hit_size = Vector2(400, 400)
	blocker.global_position = Vector2(200, 450)
	blocker.thrower_index = 1
	blocker.flight_velocity = Vector2(100, 0)
	blocker.flying = true
	p2.global_position = Vector2(210, 458)
	var before_throw_hit := p2.health
	blocker._step_flight(0.016)
	check(is_equal_approx(p2.health, before_throw_hit - 16.0), "400 by 400 thrown item deals sixteen player damage")
	var ac: GameplayAppliance = room.get_node("Appliances/ACDevice")
	ac.ignite()
	p1.global_position = ac.global_position + Vector2(0, 8)
	room._on_interact(1, p1)
	check(ac.switched_on and not ac.burning and bridge.is_burning_world(ac.global_position + Vector2(64, 20)), "turning on a burning AC blows fire to nearby grid cells")
	fan.set_fan_power(true, 1)
	check(not room._fan_has_fire(fan, room.get_node("MaterialGrid")), "fan wind has no fire boost when its air stream is clear")
	check(bridge.ignite_world(Vector2(400, 472)) and room._fan_has_fire(fan, room.get_node("MaterialGrid")), "fire in fan air stream activates grid wind boost")
	var outlet: GameplayWorldItem = room.get_node("WorldItems/Outlet")
	var cable: GameplayWorldItem = room.get_node("WorldItems/FanCable")
	p1.global_position = cable.global_position
	check(cable.pick_up(p1), "player can carry fan cable")
	room.held_items[1] = cable
	cable.global_position = outlet.global_position + Vector2(5, 0)
	room._physics_process(0.016)
	check(outlet.plugged and cable.plugged and cable.carried_by == null and not room.held_items.has(1), "nearby cable locks to outlet and leaves player's hand")
	p1.global_position = outlet.global_position + Vector2(0, 15)
	room._on_interact(1, p1)
	check(not outlet.plugged and cable.carried_by == p1, "interacting unplugs cable and returns it to player's hand")
	var trash: GameplayWorldItem = room.get_node("WorldItems/Trashcan")
	p2.health = 100.0
	p2.global_position = trash.global_position
	trash._process(0.01)
	check(p2.health == 100.0 and p2.is_physics_processing(), "touching the trashcan side does not teleport or damage player")
	p2.global_position = Vector2(trash.global_position.x, trash.global_position.y - trash.hit_size.y * 0.5 - 20.0)
	trash._process(0.01)
	p2.global_position.y += 24.0
	p2.velocity.y = 240.0
	trash._process(0.01)
	check(p2.health == 75.0 and not p2.is_physics_processing(), "falling into trash deals twenty-five HP and traps player")
	await create_timer(2.05).timeout
	check(p2.is_physics_processing() and p2.global_position.distance_to(Vector2(884, 459)) < 2.0 and p2.health == 75.0, "trash releases player outside after two seconds with remaining HP")
	room.queue_free()
	print("ITEM_SYSTEM_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
