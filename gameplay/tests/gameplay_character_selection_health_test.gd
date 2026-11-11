## Real map-menu -> Gameplay scene transition -> Eva Health integration.
## Headless by default; set CAPTURE_CHARACTER_SELECT to a path for GUI grabs.
extends SceneTree

const Selection = preload("res://gameplay/characters/character_selection_state.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func frames(number: int) -> void:
	for i in number:
		await physics_frame

func capture(phase: String) -> void:
	var prefix := OS.get_environment("CAPTURE_CHARACTER_SELECT")
	if prefix.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	RenderingServer.force_draw(false)
	var code: Error = root.get_texture().get_image().save_png(prefix + "_" + phase + ".png")
	check(code == OK, "captured real Godot scene " + phase)

func _run() -> void:
	Selection.clear()
	check(not Selection.has_selection and Selection.for_player(1) == "mage", "direct playtests keep Mage default")
	check(not Selection.choose("invalid", "mage") and not Selection.has_selection, "invalid menu choices rejected")
	var menu := (load("res://gameplay/LevelSelection/map_select.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(3)
	check(menu.player1_select.item_count == 3 and menu.player2_select.item_count == 3, "Angela map selection includes three character options for each player")
	check(menu.list.get_child_count() == 6, "original two map buttons stay present beneath both character selectors")
	check(menu.player1_select.selected == 0 and menu.player2_select.selected == 0, "fresh menu defaults to Mage for both players")
	menu.player1_select.select(1)  # Ninja
	menu.player2_select.select(2)  # Werewolf
	await capture("menu")
	menu._load_map("res://gameplay/playtest_main.tscn")
	await frames(12)
	var game := current_scene
	check(game != null and game.name == "Main", "Angela's Living Room map button loads the actual gameplay scene")
	var p1: GameplayPlayer = game.get_node("GameplayMSD/Player1")
	var p2: GameplayPlayer = game.get_node("GameplayMSD/Player2")
	check(p1.character_kind == "ninja" and p2.character_kind == "werewolf", "both menu selections are applied to the actual arena players")
	check(p1.sprite.texture.get_size() == Vector2(32, 32) and p2.sprite.texture.get_size() == Vector2(32,32), "selected Ninja and Werewolf visuals render with the supplied 32px art")
	check(is_equal_approx(p1.motor.speed, 245.0 * 1.2) and is_equal_approx(p2.motor.speed,245.0 * 0.85), "Ninja and Werewolf have their Design running speed multipliers")
	check(is_equal_approx(p1.motor.jump_speed, 460.0 * 1.12) and is_equal_approx(p2.motor.jump_speed,460.0), "Ninja jump is higher; Werewolf retains original jump speed")
	check(p1.get_node("CollisionShape2D").shape.size == Vector2(32, 64), "new characters preserve existing world/player collision contract")
	check(p1.health is Health and p2.health is Health, "both actual players use Eva's Health component rather than duplicate HP logic")
	check(p1.health.max_hp == 100 and p1.health.hp == 100, "Ninja starts with 100 real Health points")
	check(p2.health.max_hp == 160 and p2.health.hp == 160, "Werewolf starts with 160 real Health points")
	check(p1.health_label.text == "HP 100/100" and p2.health_label.text == "HP 160/160", "HUD shows numeric HP without rendering 160 individual hearts")
	await capture("gameplay")
	var ninja: GameplayCharacterVisualSet = load("res://gameplay/characters/ninja_visuals.tres")
	check(p1.health.take_damage(23), "Eva Health accepts actual Ninja damage")
	check(p1.health.hp == 77 and p1.health_label.text == "HP 77/100", "Eva Health damage updates the character's HUD")
	check(p1.sprite.texture == ninja.hurt_texture, "Health.damaged triggers the Ninja's Hurt frame")
	check(not p1.health.take_damage(10) and p1.health.hp == 77, "Eva's invulnerability window is preserved")
	p1.health._invuln_left = 0.0
	p1.health.heal(9)
	check(p1.health.hp == 86 and p1.health_label.text == "HP 86/100", "Eva Health healing updates HP text")
	check(p2.health.take_damage(30) and p2.health.hp == 130, "Werewolf damage uses the same Eva component")
	# Return via Angela's *real* Back-to-Maps component; F5 launches the
	# legacy playtest directly, and this provides a discoverable menu route.
	check(game.has_node("BackToMenu"), "actual living room exposes Angela's Back to Maps control")
	game.get_node("BackToMenu").go_to_menu()
	await frames(7)
	menu = current_scene
	check(menu.player1_select.selected == 1 and menu.player2_select.selected == 2, "returning to map selection retains the chosen Ninja and Werewolf")
	menu.player1_select.select(0)
	menu.player2_select.select(0)
	menu._load_map("res://gameplay/playtest_main.tscn")
	await frames(9)
	game = current_scene
	p1 = game.get_node("GameplayMSD/Player1")
	p2 = game.get_node("GameplayMSD/Player2")
	check(p1.character_kind == "mage" and p2.character_kind == "mage", "re-selecting Mage restores both original blue and red fighters")
	check(p1.health.max_hp == 120 and p2.health.max_hp == 120, "Mage gets 120 real Health points for both P1 and P2")
	check(is_equal_approx(p1.motor.speed,245.0) and is_equal_approx(p2.motor.jump_speed,460.0), "returning to Mage restores standard movement physics")
	Selection.clear()
	change_scene_to_file("res://gameplay/playtest_main.tscn")
	await frames(8)
	check(current_scene.get_node("GameplayMSD/Player1").character_kind == "mage", "direct scene launch without menu selection preserves Mage default")
	print("CHARACTER_SELECT_HEALTH_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
