## Actual 2D physics sweeps for thrown books, including a wall and one-way shelf.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(value: bool, label: String) -> void:
	if value: print("PASS: ",label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
func frames(n: int) -> void:
	for _i in n: await physics_frame
func launch(book: GameplayBurnableProp, at: Vector2, motion: Vector2) -> void:
	book.carried_by = null
	book.global_position = at
	book.flight_velocity = motion
	book.flying = true

func _run() -> void:
	var game: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await frames(65)
	var room: Node2D = game.get_node("GameplayMSD")
	var book: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	# Place a REAL layer-1 collider between throw origin and destination.
	var wall := StaticBody2D.new()
	wall.name = "BookWallTest"
	wall.position = Vector2(300, 365)
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(14, 170)
	shape.shape = rectangle
	wall.add_child(shape)
	room.add_child(wall)
	launch(book, Vector2(214, 372), Vector2(1700, 0))
	await frames(8)
	check(book.global_position.x <= wall.global_position.x - 7.0, "fast throw cannot tunnel through a solid wall")
	check(book.flying or book.global_position.y >= 480.0, "hitting a vertical wall cannot turn into a false mid-air landing")
	await frames(125)
	check(not book.flying and book.global_position.y <= 485.1, "wall-rebounded book finally settles on floor")
	wall.queue_free()
	await frames(3)
	# The shelf top is y338. Upward throws from underneath should pass it.
	launch(book, Vector2(245, 384), Vector2(0, -630))
	await frames(6)
	check(book.global_position.y < 340.0 and book.flying, "book rises through the one-way shelf from below")
	await frames(105)
	check(not book.flying and absf(book.global_position.y - 325.0) < 3.0, "falling book lands on the shelf top, not the floor")
	# The same jump with x outside shelf bounds should fall to world floor.
	launch(book, Vector2(350, 292), Vector2(0, 0))
	await frames(115)
	check(not book.flying and absf(book.global_position.y - 485.0) < 3.0, "book outside both shelf and table edges reaches the floor")
	# At x370, only the book's right edge overlaps the table starting near x376.
	# It should settle on the table rather than fall through its thin edge.
	launch(book, Vector2(370, 292), Vector2.ZERO)
	await frames(115)
	check(not book.flying and absf(book.global_position.y - 392.0) < 3.0, "book partially overlapping table edge lands on tabletop")
	# Sides of one-way platforms must remain passable even for fast projectiles.
	launch(book, Vector2(348, 407), Vector2(950, -180))
	await frames(5)
	check(book.global_position.x > 390.0, "book can pass through a one-way tabletop from the side/below")
	await frames(110)
	# Either player may pick up a book after it has landed and send it back.
	launch(book, Vector2(350, 292), Vector2.ZERO)
	await frames(115)
	var p2: GameplayPlayer = room.get_node("Player2")
	p2.global_position = book.global_position + Vector2(18, -7)
	p2.velocity = Vector2.ZERO
	p2.motor.reset()
	p2.facing = -1
	await frames(2)
	check(book.pick_up(p2) and book.carried_by == p2, "P2 can recover the same book after it settles")
	check(book.throw_from(p2) and book.flying and book.flight_velocity.x < 0.0, "P2 throw correctly inherits its left-facing direction")
	await frames(140)
	check(not book.flying and book.global_position.x >= 24.0 and book.global_position.x <= 936.0, "re-thrown book resolves to a stable legal world position")
	game.queue_free()
	print("BOOK_COLLISION_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
