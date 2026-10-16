## Visual regression for the repaired wall clock and independent HD-2D layers.
## No image generation service or edits to the Art Team originals.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, what: String) -> void:
	if condition:
		print("PASS: ", what)
	else:
		failures.append(what)
		push_error("FAIL: " + what)

func _run() -> void:
	var clock: Texture2D = load("res://gameplay/msd/art/clock_complete.png")
	var clock_image: Image = clock.get_image()
	check(clock_image.get_size() == Vector2i(128, 128), "complete pixel clock has its own 128x128 RGBA tile")
	var bbox: Rect2i = clock_image.get_used_rect()
	check(bbox.position.x > 0 and bbox.position.y > 0 and bbox.end.x < 128 and bbox.end.y < 128, "full round clock has clear margins on all four sides")
	check(clock_image.get_pixel(24, 64).a > 0.5 and clock_image.get_pixel(104, 64).a > 0.5, "left and right brass outer rim both exist")
	check(clock_image.get_pixel(64, 23).a > 0.5 and clock_image.get_pixel(64, 104).a > 0.5, "top and bottom rim remain intact")
	var room_image: Image = (load("res://gameplay/msd/art/living_room_pixel.png") as Texture2D).get_image()
	check(room_image.get_size() == Vector2i(960, 540), "background retains 960x540 physical world dimensions")
	var clock_offset := Vector2i(770, 76)
	check(room_image.get_pixel(clock_offset.x + 24, clock_offset.y + 64).a > 0.5 and room_image.get_pixel(clock_offset.x + 104, clock_offset.y + 64).a > 0.5, "unclipped clock is composited at the original wall position")
	for path in ["living_room_lighting.png","living_room_foreground.png","living_room_ac_glow.png","living_room_computer_glow.png"]:
		var art: Texture2D = load("res://gameplay/msd/art/" + path)
		check(art.get_size() == Vector2(960,540), path + " is scene-aligned")
		check(art.get_image().get_pixel(480, 50).a < 0.5, path + " keeps clear areas transparent")
	var game: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	for _i in 20:
		await physics_frame
	var scene: Node2D = game.get_node("GameplayMSD")
	var backdrop: CanvasItem = scene.get_node("RoomVisuals")
	var lighting: CanvasItem = scene.get_node("RoomLighting")
	var appliance: CanvasItem = scene.get_node("Appliances")
	var fx: Node2D = scene.get_node("RoomLightingFX")
	var foreground: CanvasItem = scene.get_node("RoomForeground")
	var player: CanvasItem = scene.get_node("Player1")
	check(backdrop.z_index < lighting.z_index and lighting.z_index < fx.z_index and fx.z_index < appliance.z_index and appliance.z_index < player.z_index and player.z_index < foreground.z_index, "depth plates obey backdrop > lighting > effects > furniture > players > foreground ordering")
	check(fx.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "dynamic appliance light masks remain pixel-sharp")
	var comp: GameplayAppliance = scene.get_node("Appliances/ComputerDevice")
	var ac: GameplayAppliance = scene.get_node("Appliances/ACDevice")
	check(is_zero_approx(fx.computer_intensity) and is_zero_approx(fx.ac_intensity), "lights start off when devices are off")
	comp.switched_on = true
	ac.switched_on = true
	fx._process(0.45)
	check(fx.computer_intensity > 0.9 and fx.ac_intensity > 0.9, "real appliance on states illuminate independent plates")
	comp.charred = true
	ac.switched_on = false
	fx._process(0.45)
	check(is_zero_approx(fx.computer_intensity) and is_zero_approx(fx.ac_intensity), "charred computer and turned-off AC stop glowing")
	check(scene.get_node("FridgeTop").position == Vector2(782,350) and scene.get_node("TableTop").position == Vector2(485,411), "lighting updates leave world collision platforms untouched")
	game.queue_free()
	print("ROOM_DEPTH_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
