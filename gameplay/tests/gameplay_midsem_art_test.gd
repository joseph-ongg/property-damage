## Test the actual team-slide idle sprites, animated GIF frames, recolored P2,
## redrawn room, and pixelated magic without editing Simulation-owned code.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, what: String) -> void:
	if ok:
		print("PASS: ", what)
	else:
		failures.append(what)
		push_error("FAIL: " + what)

func frames(count: int) -> void:
	for _i in count:
		await physics_frame

func _run() -> void:
	var scene: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(70)
	var arena: Node2D = scene.get_node("GameplayMSD")
	var p1: GameplayPlayer = arena.get_node("Player1")
	var p2: GameplayPlayer = arena.get_node("Player2")
	var blue := preload("res://gameplay/art/mage_1.png")
	var red := preload("res://gameplay/art/mage_2.png")
	var blue_run_0 := preload("res://gameplay/art/mage_1_run_0.png")
	var blue_run_1 := preload("res://gameplay/art/mage_1_run_1.png")
	var red_run_0 := preload("res://gameplay/art/mage_2_run_0.png")
	var red_run_1 := preload("res://gameplay/art/mage_2_run_1.png")
	check(blue.get_size() == Vector2(40, 60) and red.get_size() == Vector2(40, 60), "both PPT characters fit 40x60 sprite slots")
	check(p1.sprite.texture == blue and p2.sprite.texture == red, "standing players show Character design still PNG frames")
	check(p1.tint.b > p1.tint.r and p2.tint.r > p2.tint.b, "P1 accent is blue and P2 is red")
	for tex: Texture2D in [blue_run_0, blue_run_1, red_run_0, red_run_1]:
		check(tex.get_size() == Vector2(40, 60), "PPT GIF animation frame uses same dimensions as the still sprite")
	check(blue_run_0.get_image().get_data() != blue_run_1.get_image().get_data(), "P1 walking frames are visibly distinct")
	check(red_run_0.get_image().get_data() != red_run_1.get_image().get_data(), "P2 red walking frames are visibly distinct")

	Input.action_press("p1_right")
	Input.action_press("p2_left")
	await frames(9)
	check(p1.sprite.texture == blue_run_0 or p1.sprite.texture == blue_run_1, "P1 runs on actual GIF frames")
	check(p2.sprite.texture == red_run_0 or p2.sprite.texture == red_run_1, "P2 runs on recolored GIF frames")
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	await frames(30)
	check(p1.sprite.texture == blue and p2.sprite.texture == red, "both players restore original still artwork when movement stops")

	var room_art := preload("res://gameplay/msd/art/living_room_pixel.png")
	check(room_art.get_size() == Vector2(960, 540), "Art-team-inspired room redraw preserves 960x540 playfield")
	for tex: Texture2D in [
		preload("res://gameplay/msd/art/team_shelf.png"),
		preload("res://gameplay/msd/art/team_ac.png"),
		preload("res://gameplay/msd/art/team_fridge.png"),
		preload("res://gameplay/msd/art/team_monitor.png")
	]:
		check(tex.get_width() > 20, "Art team furniture raster extracted and loaded")
	check(arena.get_node("BookshelfTop").position == Vector2(238, 344), "shelf platform collision remains aligned")
	check(arena.get_node("TableTop").position == Vector2(485, 411), "table platform collision remains aligned")
	check(arena.get_node("FridgeTop").position == Vector2(782, 350), "fridge platform collision remains aligned")
	check(arena.get_node("FireBridge").grid() == arena.get_node("MaterialGrid"), "Art update retains material grid integration")

	var bolt: GameplayMagicBolt = GameplayMagicBolt.new()
	arena.get_node("Projectiles").add_child(bolt)
	bolt.initialize(p1)
	check(GameplayMagicBolt.FIRE_FRAMES.size() == 6, "magic uses six authored pixel fireball animation frames")
	for frame: Texture2D in GameplayMagicBolt.FIRE_FRAMES:
		check(frame.get_size() == Vector2(24,16), "pixel fireball frame is crisp 24x16")
	bolt.queue_free()
	scene.queue_free()
	print("MIDSEM_ART_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
