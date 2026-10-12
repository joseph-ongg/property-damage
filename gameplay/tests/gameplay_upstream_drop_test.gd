## 来源：Austin / chouhuaidan，sim/jackson/burn-box-render @ a529274。
## Source: Austin (chouhuaidan), commit a529274, player jump counter.
## 验证：借鉴的 ↓+跳跃下穿动作仅作用于单向平台，P1/P2 输入相互独立。
## Validate that each player drops through one-way platforms independently, never solid floors.
extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, name: String) -> void:
	if condition: print("PASS: ", name)
	else:
		failures.append(name)
		push_error("FAIL: " + name)

func frames(n: int) -> void:
	for _i in n: await physics_frame

func _run() -> void:
	var scene := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(65)
	var arena := scene.get_node("GameplayMSD")
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	check(p1.platform_drop_enabled and p2.platform_drop_enabled, "both MSD players enable optional drop action")
	check(InputMap.has_action("p1_down") and InputMap.has_action("p2_down"), "players have independent down inputs")
	for i in 2:
		var body: GameplayPlayer = p1 if i == 0 else p2
		var prefix := "p1_" if i == 0 else "p2_"
		body.global_position = Vector2(435 + i * 95, 360)
		body.velocity = Vector2.ZERO
		body.motor.reset()
		await frames(27)
		check(body.is_on_floor() and body.global_position.y < 407, "player %s lands on one-way table" % (i+1))
		var start_y := body.global_position.y
		Input.action_press(prefix + "down")
		Input.action_press(prefix + "jump")
		await frames(3)
		Input.action_release(prefix + "jump")
		Input.action_release(prefix + "down")
		check(body.platform_drop.is_dropping(), "player %s ignores only table collision while dropping" % (i+1))
		await frames(18)
		check(body.global_position.y > start_y + 28, "player %s actually falls through table" % (i+1))
		await frames(55)
		check(not body.platform_drop.is_dropping(), "player %s restores original collision" % (i+1))
		check(body.is_on_floor() and body.global_position.y > 455, "player %s lands on solid floor afterwards" % (i+1))
	# Try the same combo on the solid floor: it must not open a collision hole.
	p1.global_position = Vector2(625, 478)
	p1.velocity = Vector2.ZERO
	p1.motor.reset()
	await frames(5)
	check(not p1.platform_drop.try_drop(p1), "floor is not a one-way platform")
	Input.action_press("p1_down")
	Input.action_press("p1_jump")
	await frames(4)
	Input.action_release("p1_down")
	Input.action_release("p1_jump")
	check(absf(p1.global_position.y - 478.0) < 1.0 and p1.is_on_floor() and not p1.platform_drop.is_dropping(), "down+jump on solid floor neither jumps nor tunnels through ground")
	scene.queue_free()
	print("UPSTREAM_DROP_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
