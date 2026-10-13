## Simulation of production-style Godot AnimatableBody2D platforms; no
## upstream final scene is implied. Uses the real Gameplay player and book.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)
func frames(n: int) -> void:
	for _i in n: await physics_frame
func world_body(parent: Node, name: String, where: Vector2, size: Vector2, animated: bool = false, one_way: bool = false) -> StaticBody2D:
	var b: StaticBody2D = AnimatableBody2D.new() if animated else StaticBody2D.new()
	b.name=name
	b.global_position=where
	b.collision_layer=1
	b.collision_mask=0
	var c := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size=size
	c.shape=shape
	c.one_way_collision=one_way
	b.add_child(c)
	parent.add_child(b)
	return b
func launch(book: GameplayBurnableProp, at: Vector2, speed: Vector2 = Vector2.ZERO) -> void:
	book._reset_resting()
	book.carried_by=null
	book.global_position=at
	book.flight_velocity=speed
	book.flying=true
func put(p: GameplayPlayer, pos: Vector2) -> void:
	p.global_position=pos
	p.velocity=Vector2.ZERO
	p.motor.reset()
func capture(title: String) -> void:
	var prefix := OS.get_environment("CAPTURE_ANIM_PLATFORM")
	if prefix.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	RenderingServer.force_draw(false)
	var err: Error = root.get_texture().get_image().save_png(prefix+"_"+title+".png")
	check(err==OK,"captured actual animated-platform viewport: "+title)

func _run() -> void:
	var scene: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(60)
	var room: Node2D=scene.get_node("GameplayMSD")
	var player: GameplayPlayer=room.get_node("Player1")
	var p2: GameplayPlayer=room.get_node("Player2")
	var book: GameplayBurnableProp=room.get_node("Books/FloorBooks")
	var lift := world_body(room,"AnimatedLift",Vector2(610,320),Vector2(112,12),true,true) as AnimatableBody2D
	var wall := world_body(room,"HardStop",Vector2(769,250),Vector2(12,250))
	if not OS.get_environment("CAPTURE_ANIM_PLATFORM").is_empty():
		for entry in [
			{"node":lift,"size":Vector2(112,12),"color":Color("76a5d0",0.80)},
			{"node":wall,"size":Vector2(12,250),"color":Color("bc525b",0.80)},
		]:
			var overlay := Polygon2D.new()
			var half: Vector2=entry["size"]*0.5
			overlay.polygon=PackedVector2Array([Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(half.x,half.y),Vector2(-half.x,half.y)])
			overlay.color=entry["color"]
			overlay.z_index=13
			(entry["node"] as Node2D).add_child(overlay)
	await frames(3)
	put(player,Vector2(606,285))
	put(p2,Vector2(880,459))
	launch(book,Vector2(630,265))
	await frames(32)
	check(player.is_on_floor(),"real Gameplay CharacterBody2D grounds on an AnimatableBody2D")
	check(not book.flying and book._support==lift,"actual Gameplay book tracks an AnimatableBody2D as its support")
	var player_before:=player.global_position
	var book_before:=book.global_position
	for _i in 47:
		lift.global_position += Vector2(1.45,0)
		await frames(1)
	check(player.global_position.x > player_before.x + 37.0,"player rides animated platform horizontally without walking")
	check(book.global_position.x > book_before.x + 37.0,"book rides the same animated platform")
	check(player.is_on_floor(),"player remains grounded on moving one-way platform")
	await capture("ride")
	# Platform's wall-pressure shouldn't let the player/book cross layer-1 wall.
	for _i in 70:
		lift.global_position += Vector2(1.45,0)
		await frames(1)
	var player_width: float=16.0
	check(player.global_position.x <= wall.global_position.x-6.0-player_width+2.0,"player is not pushed through wall by AnimatableBody2D")
	check(book.global_position.x <= wall.global_position.x-6.0-14.0+2.0,"book is not pushed through wall by AnimatableBody2D")
	check(not is_nan(player.global_position.x) and not is_nan(book.global_position.x),"pressure never produces invalid coordinates")
	await capture("wall")
	# Remove obstacle and let the lift descend/ascend slowly under a roof.
	wall.queue_free()
	await frames(4)
	lift.global_position=Vector2(610,320)
	put(player,Vector2(606,285))
	launch(book,Vector2(636,265))
	await frames(40)
	var roof:=world_body(room,"Ceiling",Vector2(610,183),Vector2(160,14))
	if not OS.get_environment("CAPTURE_ANIM_PLATFORM").is_empty():
		var roof_indicator:=Polygon2D.new()
		roof_indicator.color=Color("a77ccc",0.90)
		roof_indicator.polygon=PackedVector2Array([Vector2(-80,-7),Vector2(80,-7),Vector2(80,7),Vector2(-80,7)])
		roof_indicator.z_index=13
		roof.add_child(roof_indicator)
	await frames(3)
	var book_before_y:float=book.global_position.y
	var player_before_y:float=player.global_position.y
	for _i in 32:
		lift.global_position.y-=1.65
		await frames(1)
	check(book.global_position.y < book_before_y-22.0,"book follows upward-moving AnimatableBody2D")
	check(player.global_position.y < player_before_y-20.0,"player follows upward-moving AnimatableBody2D")
	# Continue upward until book nears ceiling; it must not tunnel through.
	var roof_violation := false
	var released_at_roof := false
	for _i in 55:
		lift.global_position.y-=1.65
		await frames(1)
		if book.global_position.y < roof.global_position.y+7.0+13.0-1.5:
			roof_violation=true
		if book.flying and book._support != lift:
			released_at_roof=true
	check(not roof_violation and book.global_position.y >= roof.global_position.y+7.0+13.0-1.5,"book never crosses the solid roof on any physics frame")
	check(released_at_roof,"book drops moving-platform support when it contacts the roof")
	# CharacterBody may drop support when pushed into the ceiling; preserve
	# a no-tunnelling invariant and explicitly report support behavior.
	var player_c: CollisionShape2D=player.get_node("CollisionShape2D")
	var top:float=player.global_position.y+player_c.position.y-(player_c.shape as RectangleShape2D).size.y/2.0
	check(top >= roof.global_position.y+7.0-2.0,"player's real collision shape never passes through roof")
	print("ANIM_LIFT_ROOF_STATE grounded=",player.is_on_floor()," book_flying=",book.flying," player=",player.global_position," book=",book.global_position)
	await capture("roof")
	# Disable collision on the live animated platform. The book and player
	# should fall onto world or lower furniture and remain finite.
	lift.collision_layer=0
	await frames(115)
	check(not book.flying and book.global_position.y<=485.2,"book finds a real lower surface after support disabled")
	check(player.global_position.y<=490.0 and not is_nan(player.global_position.y),"player survives support loss and falls safely")
	await capture("release")
	scene.queue_free()
	print("ANIM_PLATFORM_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
