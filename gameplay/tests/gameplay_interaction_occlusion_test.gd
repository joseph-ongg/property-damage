## Solid walls must prevent reaching books/devices through geometry.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
func frames(n: int) -> void:
	for _i in n: await physics_frame
func wall(parent: Node, where: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "TestInteractionWall"
	body.position = where
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12, 98)
	collider.shape = box
	body.add_child(collider)
	parent.add_child(body)
	return body
func put(player: GameplayPlayer, where: Vector2) -> void:
	player.global_position = where
	player.velocity = Vector2.ZERO
	player.motor.reset()

func capture(label: String) -> void:
	var prefix := OS.get_environment("CAPTURE_INTERACTION_LOS")
	if prefix.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	RenderingServer.force_draw(false)
	var error: Error = root.get_texture().get_image().save_png(prefix + "_" + label + ".png")
	check(error == OK, "saved real Godot viewport with wall test: " + label)

func _run() -> void:
	var scene: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(65)
	var room: Node2D = scene.get_node("GameplayMSD")
	var player: GameplayPlayer = room.get_node("Player1")
	var other: GameplayPlayer = room.get_node("Player2")
	var book: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	var fridge: GameplayAppliance = room.get_node("Appliances/FridgeDevice")
	put(other, Vector2(850,478))
	book.global_position = Vector2(523,478)
	book.flying = false
	book.carried_by = null
	put(player, Vector2(476,478))
	var obstruction := wall(room, Vector2(500, 461))
	if not OS.get_environment("CAPTURE_INTERACTION_LOS").is_empty():
		var marker := ColorRect.new()
		marker.color = Color("a5414c", 0.96)
		marker.position = Vector2(-6, -49)
		marker.size = Vector2(12, 98)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.z_index = 13
		obstruction.add_child(marker)
	await frames(4)
	check(player.global_position.distance_to(book.global_position) < book.pickup_radius, "book lies within nominal pickup range across solid wall")
	check(not book.can_pick_up(player), "P1 cannot pick up a book through a wall")
	check(room.get_interaction_offer(player).get("target") != book, "P1 prompt does not advertise an unreachable book")
	await capture("blocked")
	Input.action_press("p1_interact")
	await frames(2)
	Input.action_release("p1_interact")
	check(book.carried_by == null, "interact action cannot acquire the book behind wall")
	obstruction.queue_free()
	await frames(3)
	check(book.can_pick_up(player), "book pickup still works after obstacle removal")
	check(room.get_interaction_offer(player).get("target") == book, "valid book is offered when there is clear line of sight")
	if not OS.get_environment("CAPTURE_INTERACTION_LOS").is_empty():
		# The previous blocked attempt temporarily said NO OBJECT IN REACH.
		# Wait for its normal status timeout before making a user-facing
		# comparison of the actual hint panels.
		await frames(145)
	await capture("clear")
	Input.action_press("p1_interact")
	await frames(2)
	Input.action_release("p1_interact")
	check(book.carried_by == player, "P1 can actually pick up the book using E after the wall is removed")
	await frames(3)
	Input.action_press("p1_interact")
	await frames(2)
	Input.action_release("p1_interact")
	check(book.carried_by == null and book.flying, "P1 can throw the previously blocked book after retrieving it")
	book.flying = false
	book._reset_resting()
	# Cleanly set up independent device case; do not mutate the shared scene.
	put(player, Vector2(726, 478))
	book.global_position = Vector2(325, 485)
	var device_wall := wall(room, Vector2(754, 461))
	await frames(4)
	check(player.global_position.distance_to(fridge.interaction_point()) < fridge.interaction_radius, "fridge control within nominal interaction range across wall")
	check(not fridge.can_interact(player), "solid wall prevents P1 from reaching fridge controls")
	check(room.get_interaction_offer(player).get("target") != fridge, "HUD must not prompt an unreachable fridge")
	Input.action_press("p1_interact")
	await frames(2)
	Input.action_release("p1_interact")
	check(not fridge.switched_on, "blocked fridge cannot be opened through the wall")
	device_wall.queue_free()
	await frames(4)
	check(fridge.can_interact(player), "fridge controls are reachable with barrier removed")
	check(room.get_interaction_offer(player).get("target") == fridge, "fridge appears in HUD when accessible")
	Input.action_press("p1_interact")
	await frames(2)
	Input.action_release("p1_interact")
	check(fridge.switched_on, "normal unobstructed fridge interaction remains functional")
	# One-way furniture tops are pass-through, not opaque world walls. Their
	# actual CollisionShape2D must not block a book reachable from underneath.
	put(player, Vector2(240, 366))
	# Move the other prototype book piles out of pickup range, so this tests
	# line of sight rather than the controller's nearest-book priority.
	for candidate: GameplayBurnableProp in room.get_node("Books").get_children():
		if candidate != book:
			candidate.global_position = Vector2(900, 485)
	book.global_position = Vector2(245, 325)
	await frames(3)
	check(book.can_pick_up(player), "one-way bookshelf does not block nearby book pickup from below")
	check(room.get_interaction_offer(player).get("target") == book, "the one-way shelf continues to show a correct PICK BOOK prompt")
	# P2 uses the same shared geometry, so the guard must not be P1-specific.
	put(other, Vector2(240, 366))
	await frames(2)
	check(book.can_pick_up(other), "P2 shares the same pass-through pickup behavior")
	# Distance limits still apply independently of line of sight.
	put(other, Vector2(900, 478))
	await frames(2)
	check(not book.can_pick_up(other), "reachability never bypasses the existing pickup radius")
	scene.queue_free()
	print("INTERACTION_OCCLUSION_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
