## Art-team clock repair and Octopath-inspired 2D depth are visual only.
## Test color symmetry, transparent passes and unchanged real gameplay layers.
extends SceneTree

var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, detail: String) -> void:
	if ok: print("PASS: ", detail)
	else:
		failures.append(detail)
		push_error("FAIL: " + detail)

func _run() -> void:
	var game: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	for _i in 6: await physics_frame
	var arena: Node2D = game.get_node("GameplayMSD")
	var background: Node2D = arena.get_node("RoomVisuals")
	var lighting: Node2D = arena.get_node("RoomLighting")
	var front: Node2D = arena.get_node("RoomForeground")
	var p1: GameplayPlayer = arena.get_node("Player1")
	var material: Node2D = arena.get_node("TeamMaterialRenderer")
	var room_img := preload("res://gameplay/msd/art/living_room_pixel.png").get_image()
	var light_img := preload("res://gameplay/msd/art/living_room_lighting.png").get_image()
	var front_img := preload("res://gameplay/msd/art/living_room_foreground.png").get_image()
	check(room_img.get_size() == Vector2i(960,540), "base 960x540 room stays on original viewport")
	check(light_img.get_size() == Vector2i(960,540) and front_img.get_size() == Vector2i(960,540), "two new pixel depth plates retain viewport dimensions")
	check(background.z_index < material.z_index and material.z_index < lighting.z_index and lighting.z_index < p1.z_index and p1.z_index < front.z_index,
		"wall, material, atmosphere, actor and corner foreground sort in depth order")
	check(lighting.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and front.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
		"depth textures use nearest-neighbor pixel filtering")
	check(not (lighting as Node2D).get("foreground") and (front as Node2D).get("foreground"), "back light and front occluder draw separate texture sources")
	check(light_img.get_pixel(160,180).a > 0.0 and light_img.get_pixel(160,180).a < 0.8, "window atmosphere is translucent, not a solid 2D sheet")
	var has_corner_leaf := false
	for x in range(4, 65, 4):
		for y in range(385, 497, 8):
			if front_img.get_pixel(x,y).a > 0.1:
				has_corner_leaf = true
	check(has_corner_leaf and front_img.get_pixel(480,350).a < 0.01, "corner plants add depth without hiding central interactions")
	# Clock is procedurally repaired in room generator; both sides must show
	# the same ivory face. Original PPT crop cuts off the rightmost side.
	var cx := 417 * 2
	var cy := 70 * 2
	var ivory_l: Color = room_img.get_pixel(cx - 9*2,cy)
	var ivory_r: Color = room_img.get_pixel(cx + 9*2,cy)
	check(ivory_l.r > .75 and ivory_l.g > .65 and ivory_r.r > .75 and ivory_r.g > .65,
		"complete pale clock face extends left and right of its center")
	var border_l: Color = room_img.get_pixel(cx - 20*2,cy)
	var border_r: Color = room_img.get_pixel(cx + 20*2,cy)
	check(border_l.r < .65 and border_r.r < .65, "clock has complete bezel on left and right")
	check(absf(border_l.r-border_r.r) < .22, "full clock rim has consistent shading")
	check(room_img.get_pixel(cx,cy).r > .50, "clock's central spindle and hands are visible")
	check(arena.get_node("BookshelfTop").position == Vector2(238,344) and arena.get_node("FridgeTop").position == Vector2(782,350),
		"room depth improvement does not change real one-way platform coordinates")
	check(arena.get_node("MaterialGrid") is MaterialGrid and arena.get_node("FireBridge").grid() == arena.get_node("MaterialGrid"),
		"lighting and foreground do not interfere with Simulation grid state")
	game.queue_free()
	print("ROOM_DEPTH_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
