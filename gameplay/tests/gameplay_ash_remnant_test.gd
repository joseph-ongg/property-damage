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


func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame


func remnants_in(room: Node) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node: Node in get_nodes_in_group("visual_ash_remnants"):
		if room.is_ancestor_of(node):
			var remnant := node as Node2D
			if remnant != null:
				result.append(remnant)
	return result


func burn_item(item: GameplayInteractableItem) -> void:
	item.burn_damage_interval = 0.1
	item.burn_duration = 10.0
	item.ignite()
	for _i in range(ceili(item.hp)):
		item._process(0.11)


func nearest_remnant(room: Node, x: float) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for remnant: Node2D in remnants_in(room):
		var distance := absf(remnant.global_position.x - x)
		if distance < nearest_distance:
			nearest = remnant
			nearest_distance = distance
	return nearest


func _run() -> void:
	var scene := load("res://gameplay/msd/gameplay_msd.tscn") as PackedScene
	var room := scene.instantiate() as Node2D
	root.add_child(room)
	await frames(2)

	var book := room.get_node("Books/FloorBooks") as GameplayBurnableProp
	var plant := room.get_node("WorldItems/Plant") as GameplayWorldItem
	var computer := room.get_node("Appliances/ComputerDevice") as GameplayAppliance
	var clock := room.get_node("WorldItems/Clock") as GameplayWorldItem
	var p1 := room.get_node("Player1") as GameplayPlayer
	var p2 := room.get_node("Player2") as GameplayPlayer
	var initial_p1_hp: int = p1.health_component.hp
	var initial_p2_hp: int = p2.health_component.hp
	var initial_p1_rewards: int = p1.destroyed_objects
	var initial_p2_rewards: int = p2.destroyed_objects

	book.global_position = Vector2(920.0, 200.0)
	book.burn_damage_interval = 0.1
	book.burn_duration = 10.0
	book.ignite()
	book._process(0.11)
	check(not book.destroyed_item and not book.ash_visual_transferred
		and remnants_in(room).is_empty(), "partial book burn does not transfer ash")
	book._process(0.11)
	book._process(0.11)
	check(book.destroyed_item and book.burned_to_ash and book.ash_visual_transferred,
		"book transfers ash only after fire damage destroys it")
	check(remnants_in(room).size() == 1, "book destruction creates one remnant")
	var book_remnant: Node2D = nearest_remnant(room, 920.0)

	plant.global_position = Vector2(238.0, 180.0)
	burn_item(plant)
	computer.global_position = Vector2(455.0, 250.0)
	burn_item(computer)
	check(plant.ash_visual_transferred and computer.ash_visual_transferred
		and remnants_in(room).size() == 3,
		"WorldItem and genuinely burned appliance each transfer one remnant")
	plant._process(0.11)
	computer._process(0.11)
	check(remnants_in(room).size() == 3, "repeated processing cannot duplicate transferred ash")

	await frames(100)
	var plant_remnant: Node2D = nearest_remnant(room, 238.0)
	var computer_remnant: Node2D = nearest_remnant(room, 455.0)
	check(bool(book_remnant.get("settled")) and absf(book_remnant.global_position.y - 498.0) < 3.0,
		"book ash falls to the room floor")
	check(bool(plant_remnant.get("settled")) and absf(plant_remnant.global_position.y - 338.0) < 3.0,
		"WorldItem ash settles on the one-way bookshelf platform")
	check(bool(computer_remnant.get("settled")) and absf(computer_remnant.global_position.y - 405.0) < 3.0,
		"appliance ash settles on the tabletop")

	var furniture := room.get_node("MaterialGrid/FurnitureFireLayer") as GameplayFurnitureFireLayer
	var table := room.get_node("TableTop") as StaticBody2D
	furniture._destroy("TABLE")
	await frames(3)
	check(table.collision_layer == 0 and not bool(computer_remnant.get("settled")),
		"destroying the platform releases settled ash")
	await frames(100)
	check(bool(computer_remnant.get("settled")) and absf(computer_remnant.global_position.y - 498.0) < 3.0,
		"released appliance ash falls to the next valid surface")

	clock.take_damage(clock.hp, 1)
	check(p1.destroyed_objects == initial_p1_rewards + 1
		and p2.destroyed_objects == initial_p2_rewards,
		"original item destruction reward still occurs exactly once")
	check(remnants_in(room).size() == 3,
		"non-fire destruction does not create an ash remnant")
	check(p1.health_component.hp == initial_p1_hp and p2.health_component.hp == initial_p2_hp
		and p1.destroyed_objects == initial_p1_rewards + 1
		and p2.destroyed_objects == initial_p2_rewards,
		"falling ash causes no damage or additional destruction rewards")
	check(not (computer_remnant is CollisionObject2D)
		and not computer_remnant.is_in_group("interactable_items"),
		"ash remnant has no collision or item interaction")

	room.queue_free()
	await frames(2)
	check(not is_instance_valid(book_remnant), "arena cleanup frees its ash remnants")
	var fresh_room := scene.instantiate() as Node2D
	root.add_child(fresh_room)
	await frames(2)
	check(remnants_in(fresh_room).is_empty(), "a fresh scene starts without old ash remnants")
	fresh_room.queue_free()
	await frames(2)

	var playtest_scene := load("res://gameplay/integration/two_map_playtest/two_map_playtest.tscn") as PackedScene
	var playtest := playtest_scene.instantiate() as Node2D
	root.add_child(playtest)
	await frames(2)
	playtest.call("_on_map_selected", "res://gameplay/playtest_main.tscn")
	await frames(2)
	var living_arena := playtest.get("arena") as Node2D
	var arena_book := living_arena.get_node("Books/FloorBooks") as GameplayBurnableProp
	arena_book.global_position = Vector2(920.0, 200.0)
	burn_item(arena_book)
	var arena_remnant: Node2D = nearest_remnant(living_arena, 920.0)
	check(arena_remnant != null, "two-map Living Room arena owns its ash remnant")
	playtest.call("_on_map_selected", "res://gameplay/garden/garden_level.tscn")
	await frames(2)
	var garden_arena := playtest.get("arena") as Node2D
	check(not is_instance_valid(arena_remnant) and remnants_in(garden_arena).is_empty(),
		"changing maps frees the old arena's ash and starts clean")
	playtest.queue_free()
	await frames(2)

	print("ASH_REMNANT_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
