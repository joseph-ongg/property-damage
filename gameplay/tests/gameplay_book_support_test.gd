## Resting books should react to platform transforms, loss of support and ledges.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)
func frames(count: int) -> void:
	for _i in count: await physics_frame
func toss(book: GameplayBurnableProp, at: Vector2, speed: Vector2 = Vector2.ZERO) -> void:
	book.carried_by = null
	book.global_position = at
	book.flight_velocity = speed
	book.flying = true

func _run() -> void:
	var instance: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(instance)
	await frames(65)
	var room: Node2D = instance.get_node("GameplayMSD")
	var book: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	var table: StaticBody2D = room.get_node("TableTop")
	var shelf: StaticBody2D = room.get_node("BookshelfTop")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	# Static landing must remain stable and the book must identify a support.
	toss(book, Vector2(485, 335))
	await frames(115)
	check(not book.flying and absf(book.global_position.y - 392.0) < 2.0, "book settles on actual tabletop")
	var before := book.global_position
	table.global_position += Vector2(26.0, -9.0)
	await frames(4)
	check(book.global_position.distance_to(before + Vector2(26.0, -9.0)) < 3.0, "resting book follows moving table without floating")
	table.collision_layer = 0
	await frames(10)
	check(book.flying and book.global_position.y > before.y + 10.0, "disabled table collision releases book to gravity")
	await frames(100)
	check(not book.flying and absf(book.global_position.y - 485.0) < 3.0, "book settles on physical floor after table loses collision")
	# Retrieval after a support loss: either player can pick up and throw.
	p1.global_position = book.global_position + Vector2(-14, -5)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	await frames(3)
	check(book.pick_up(p1) and book.carried_by == p1, "P1 can retrieve a book that fell from a changed platform")
	check(book.throw_from(p1) and book.flying, "retrieved book can be thrown again")
	await frames(100)
	p2.global_position = book.global_position + Vector2(14, -5)
	p2.velocity = Vector2.ZERO
	p2.motor.reset()
	await frames(3)
	check(book.pick_up(p2) and book.carried_by == p2, "P2 can retrieve the same settled book")
	check(book.throw_from(p2), "P2 can throw a recovered book")
	await frames(120)
	# Simulate sliding just beyond the shelf's last usable contact point.
	toss(book, Vector2(245, 250))
	await frames(100)
	check(not book.flying and absf(book.global_position.y - 325.0) < 2.0, "book lands on one-way bookshelf platform")
	book.global_position.x = 356.0
	await frames(8)
	check(book.flying and book.global_position.y > 325.0, "book pushed off shelf edge falls rather than floating")
	await frames(100)
	check(not book.flying and absf(book.global_position.y - 485.0) < 3.0, "book slides beyond shelf and settles on floor")
	# Land very near the shelf edge with forward throw momentum. The brief
	# post-contact slide should take it past its last support ray, then gravity
	# should bring it safely to the floor without any manual teleport.
	toss(book, Vector2(329,321), Vector2(220,140))
	await frames(15)
	check(book.global_position.x > 339.0 and book.flying, "landing momentum naturally slides a marginally supported book off its ledge")
	await frames(110)
	check(not book.flying and absf(book.global_position.y - 485.0) < 3.0, "momentum slide finishes on the floor after leaving shelf")
	# Remove the source platform entirely while a separate book rests on it.
	var other: GameplayBurnableProp = room.get_node("Books/ShelfBooks")
	toss(other, Vector2(245, 250))
	await frames(95)
	check(not other.flying, "second book is supported before platform is freed")
	shelf.queue_free()
	await frames(8)
	check(other.flying and other.global_position.y > 325.0, "freeing a supporting StaticBody2D safely releases its book")
	await frames(110)
	check(not other.flying and absf(other.global_position.y - 485.0) < 3.0, "book lands on world floor after its platform is deleted")
	instance.queue_free()
	print("BOOK_SUPPORT_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
