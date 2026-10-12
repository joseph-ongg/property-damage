## Verify that regenerated artwork, 32x64 physics and compact HUD agree.
## Checks actual runtime Texture2D dimensions and font-measured text width.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)


func _run() -> void:
	var scene := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for _i in 5:
		await physics_frame
	var room: Node2D = scene.get_node("GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var hud: CanvasLayer = room.get_node("HUD")
	var art := preload("res://gameplay/msd/art/living_room_pixel.png")
	check(art.get_size() == Vector2(960, 540), "living-room pixel art exactly fills the design viewport")
	for player: GameplayPlayer in [p1, p2]:
		var shape: CollisionShape2D = player.get_node("CollisionShape2D")
		var sprite: Sprite2D = player.get_node("Sprite2D")
		var texture: Texture2D = sprite.texture
		var id := "P%d" % player.player_index
		check(texture.get_size() == Vector2(736, 736), id + " uses original uncropped 736x736 Art Team sprite texture")
		check(is_equal_approx(sprite.scale.x,60.0/736.0) and is_equal_approx(sprite.scale.y,60.0/736.0), id + " scales the original art in Godot rather than downsampling it")
		check((shape.shape as RectangleShape2D).size == Vector2(32, 64), id + " keeps Angela-compatible 32x64 collision")
		check(shape.position == Vector2(0, -12) and is_equal_approx(sprite.position.y, -10.0), id + " has matching collider and visual anchor")
		check(is_equal_approx(sprite.position.y + texture.get_height() * sprite.scale.y * 0.5, shape.position.y + (shape.shape as RectangleShape2D).size.y * 0.5), id + " original texture feet align with physical feet")
		check(player.get_node("NameTag").offset_bottom < -41.0, id + " name is positioned above the hat")
		check(player.get_node("JumpCharges").offset_bottom < player.get_node("NameTag").offset_top, id + " double-jump markers are not over the name")

	for label_name in ["Title", "Subtitle", "SystemHint", "StatusHeading", "SparkStatus", "P1Tag", "Controls", "ControlsExtraP1", "P2Tag", "ControlsP2", "ControlsExtraP2"]:
		var label: Label = hud.get_node(label_name)
		var font: Font = label.get_theme_font("font")
		var fontsize: int = label.get_theme_font_size("font_size")
		var text_size: float = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fontsize).x
		check(text_size <= label.offset_right - label.offset_left + 1.0, label_name + " text fits in its HUD panel")

	check(hud.get_node("TopBar").offset_bottom < 75 and hud.get_node("StatusBack").offset_bottom < 75, "top HUD stays clear of the furniture and play field")
	check(hud.get_node("BottomStrip").offset_top >= 500, "bottom HUD stays below the physical floor level")
	check(room.get_node("RoomVisuals").z_index < p1.z_index and room.get_node("Appliances").z_index < p1.z_index, "redesigned backdrop and furniture remain behind players")

	scene.queue_free()
	print("VISUAL_DESIGN_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
