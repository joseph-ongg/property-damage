## Test real magic projectile against world collision and reachable props.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, name: String) -> void:
	if ok: print("PASS: ",name)
	else:
		failures.append(name)
		push_error("FAIL: " + name)
func frames(n: int) -> void:
	for _i in n: await physics_frame

func _run() -> void:
	var game: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await frames(65)
	var room: Node2D = game.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var target: GameplayBurnableProp = room.get_node("Books/FloorBooks")
	var obstacle := StaticBody2D.new()
	obstacle.name = "TestMagicBarrier"
	obstacle.position = Vector2(500, 456)
	obstacle.collision_layer = 1
	obstacle.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 120)
	shape.shape = rect
	obstacle.add_child(shape)
	room.add_child(obstacle)
	p1.global_position = Vector2(450,478)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	p1.facing = 1
	target.global_position = Vector2(523,471)
	await frames(5)
	check(not target.scorched, "book behind test barrier initially intact")
	Input.action_press("p1_attack")
	await frames(2)
	Input.action_release("p1_attack")
	await frames(20)
	check(not target.scorched, "solid world barrier blocks magic from scorching a book behind it")
	check(room.get_node("Projectiles").get_child_count() == 0,"magic bolt is consumed by solid world collision")
	# Computer interaction uses a wider 49px radius than books. It can be
	# triggered *before* the projectile reaches a blocking wall unless each
	# proximity hit also verifies line of sight to the actual object.
	var computer: GameplayAppliance = room.get_node("Appliances/ComputerDevice")
	target.global_position = Vector2(343, 485)
	computer.global_position = Vector2(535, 471)
	p1._magic_cooldown = 0.0
	Input.action_press("p1_attack")
	await frames(2)
	Input.action_release("p1_attack")
	await frames(20)
	check(not computer.charred, "computer behind a solid wall cannot be shorted by an earlier proximity check")
	# Restore the computer to its original desk position, so the next cast
	# tests the unobstructed BOOK, not the computer.
	computer.global_position = Vector2(552, 404)
	target.global_position = Vector2(523, 471)
	obstacle.queue_free()
	await frames(3)
	p1._magic_cooldown = 0.0
	Input.action_press("p1_attack")
	await frames(2)
	Input.action_release("p1_attack")
	await frames(20)
	check(target.scorched, "magic can scorch the same book once the barrier is removed")
	# A clear shot must still short the computer; this is a regression guard
	# for the new line-of-sight check, not just a rejection-only test.
	target.global_position = Vector2(343, 485)
	computer.global_position = Vector2(535, 471)
	p1._magic_cooldown = 0.0
	Input.action_press("p1_attack")
	await frames(2)
	Input.action_release("p1_attack")
	await frames(20)
	check(computer.charred, "unobstructed magic can still short a nearby computer")
	game.queue_free()
	print("MAGIC_OCCLUSION_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
