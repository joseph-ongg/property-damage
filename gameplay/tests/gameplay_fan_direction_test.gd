## Regression: fan airflow begins at its own coordinate and travels ONLY toward its face.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func frames(count: int) -> void:
	for _i in count: await physics_frame
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)
func move_player(p: GameplayPlayer, where: Vector2) -> void:
	p.global_position=where
	p.velocity=Vector2.ZERO
	p.motor.reset()

func _run() -> void:
	var scene := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(65)
	var room: Node2D=scene.get_node("GameplayMSD")
	var fan: GameplayAppliance=room.get_node("Appliances/FanDevice")
	var p1: GameplayPlayer=room.get_node("Player1")
	var p2: GameplayPlayer=room.get_node("Player2")
	var conditions: Node2D=room.get_node("PlayerConditions")
	fan.set_fan_power(true)
	var x:float=fan.global_position.x
	var y:float=fan.global_position.y
	move_player(p1, Vector2(x-36,y+89))
	move_player(p2, Vector2(x+36,y+89))
	await frames(4)
	check(fan.applies_to(p1) and p1.motor.environment_acceleration_x < -100.0,"player left of fan receives westward wind")
	check(not fan.applies_to(p2) and is_zero_approx(p2.motor.environment_acceleration_x),"player to right receives no vacuum pull")
	check(conditions.get_condition(p1)=="WIND" and conditions.get_condition(p2)!="WIND","WIND UI is restricted to downwind player")
	var left_before := p1.global_position.x
	var right_before := p2.global_position.x
	await frames(14)
	check(p1.global_position.x < left_before - 4.0,"actual physics carries left player west")
	check(absf(p2.global_position.x - right_before) < 1.0,"actual physics leaves right player stationary")
	move_player(p1,Vector2(x+1,y+10))
	await frames(3)
	check(not fan.applies_to(p1) and is_zero_approx(p1.motor.environment_acceleration_x),"strict fan origin right +1px is excluded")
	move_player(p1,Vector2(x-1,y+10))
	await frames(3)
	check(fan.applies_to(p1),"strict fan origin left -1px is included")
	move_player(p1,Vector2(x-fan.effect_radius-1,y+10))
	await frames(3)
	check(not fan.applies_to(p1),"past horizontal reach is excluded")
	move_player(p1,Vector2(x-35,y+150))
	await frames(3)
	check(not fan.applies_to(p1),"below wind band is excluded")
	move_player(p1,Vector2(x-35,y-90))
	await frames(3)
	check(not fan.applies_to(p1),"above wind band is excluded")
	fan.fan_facing_left=false
	move_player(p1,Vector2(x+36,y+89))
	move_player(p2,Vector2(x-36,y+89))
	await frames(4)
	check(fan.applies_to(p1) and p1.motor.environment_acceleration_x > 100.0,"reversed fan pushes right of origin")
	check(not fan.applies_to(p2) and is_zero_approx(p2.motor.environment_acceleration_x),"reversed fan never pushes player behind it")
	fan.fan_facing_left=true
	fan.set_fan_power(false)
	await frames(4)
	check(not fan.applies_to(p1) and not fan.applies_to(p2),"power off disables all wind effects")
	# Interactions still allowed at either side; wind application is separate.
	move_player(p1,Vector2(x+20,y+89))
	await frames(4)
	check(fan.can_interact(p1),"player behind fan can still reach the on/off switch")
	scene.queue_free()
	print("FAN_DIRECTION_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
