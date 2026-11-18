## Character art and character-select API in the actual Godot Gameplay arena.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func frames(n: int) -> void:
	for _i in n:
		await physics_frame

func tap_character_key(code: Key) -> void:
	# A real keystroke needs distinct press/release events on separate frames.
	# Reusing an InputEvent object or leaving keys held makes Godot synthetic
	# input non-deterministic and can swallow a later character selection.
	var press := InputEventKey.new()
	press.keycode = code
	press.pressed = true
	Input.parse_input_event(press)
	await frames(3)
	var release := InputEventKey.new()
	release.keycode = code
	release.pressed = false
	Input.parse_input_event(release)
	await frames(2)


func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ",label)
	else:
		push_error("FAIL: " + label)
		failures.append(label)

func capture(name: String) -> void:
	var prefix: String = OS.get_environment("CHARACTER_SCREENSHOTS")
	if prefix.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	RenderingServer.force_draw(false)
	var code: Error = root.get_texture().get_image().save_png(prefix + "_" + name + ".png")
	check(code == OK, "actual Godot viewport saved for " + name)

func _run() -> void:
	var scene: Node2D = (load("res://gameplay/characters/character_demo.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await frames(80)
	var room: Node2D = scene.get_node("Main/GameplayMSD")
	var p1: GameplayPlayer = room.get_node("Player1")
	var p2: GameplayPlayer = room.get_node("Player2")
	var ninja: GameplayCharacterVisualSet = load("res://gameplay/characters/ninja_visuals.tres")
	var wolf: GameplayCharacterVisualSet = load("res://gameplay/characters/werewolf_visuals.tres")
	check(p1.character_kind == "ninja" and p2.character_kind == "werewolf", "character demo assigns both new playable characters")
	check(p1.player_index == 1 and p2.player_index == 2, "character choice preserves independent P1/P2 input bindings")
	check(is_equal_approx(p1.motor.speed, 245.0 * 1.2), "Ninja runs at Design 1.2x speed")
	check(is_equal_approx(p2.motor.speed, 245.0 * 0.85), "Werewolf runs at Design 0.85x speed")
	check(is_equal_approx(p1.motor.jump_speed, 460.0 * 1.12), "Ninja has an increased jump speed")
	check(p1.character_design_info()["design_hp"] == 100 and p2.character_design_info()["design_hp"] == 160, "character design HP metadata is exposed without overriding Health")
	check(p2.character_design_info()["projectile"] == "TBD", "unconfirmed Werewolf projectile is not invented")
	var p1_shape: CollisionShape2D = p1.get_node("CollisionShape2D")
	check((p1_shape.shape as RectangleShape2D).size == Vector2(32,64) and p1.collision_mask == 1 and p1.collision_layer == 2, "new art preserves original collision body and world/player layers")
	check(p1.sprite.texture.get_size() == Vector2(32,32) and p2.sprite.texture.get_size() == Vector2(32,32), "both new character images render from 32x32 pixel plates")
	check(ninja.idle_frames.has(p1.sprite.texture) and wolf.idle_frames.has(p2.sprite.texture), "both players idle with character-specific frames")
	check(p2.sprite.flip_h, "P2 faces left, using the existing flip rule")
	# Place both players in unobstructed stage space only for visual capture.
	# The actual character demo continues using the normal arena spawns.
	if not OS.get_environment("CHARACTER_SCREENSHOTS").is_empty():
		p1.global_position = Vector2(355,459)
		p2.global_position = Vector2(670,459)
		p1.velocity = Vector2.ZERO
		p2.velocity = Vector2.ZERO
		p1.motor.reset()
		p2.motor.reset()
		await frames(6)
	await capture("idle")
	# Test movement animation with real inputs, not by forcing a visual state.
	Input.action_press("p1_right")
	Input.action_press("p2_left")
	await frames(12)
	check(ninja.run_frames.has(p1.sprite.texture) and wolf.run_frames.has(p2.sprite.texture), "P1 and P2 show animated Run frames during real movement")
	await capture("run")
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	await frames(16)
	Input.action_press("p1_jump")
	await frames(3)
	Input.action_release("p1_jump")
	check(p1.velocity.y < 0.0 and p1.sprite.texture == ninja.jump_texture, "Ninja uses Jump pose while the motor jumps")
	await frames(50)
	Input.action_press("p1_attack")
	Input.action_press("p2_attack")
	await frames(2)
	Input.action_release("p1_attack")
	Input.action_release("p2_attack")
	check(p1.sprite.texture == ninja.action_texture and p2.sprite.texture == wolf.action_texture, "Ninja and Werewolf action art follows both players' Attack inputs")
	await capture("attack")
	p1.show_hurt_pose()
	p2.show_hurt_pose()
	check(p1.sprite.texture == ninja.hurt_texture and p2.sprite.texture == wolf.hurt_texture, "Hurt poses can be triggered by a future Health adapter")
	await frames(25)
	check(p1.sprite.texture != ninja.hurt_texture and p2.sprite.texture != wolf.hurt_texture, "Hurt pose automatically expires")
	check(not p1.set_character_kind("unknown"), "invalid character selection is rejected")
	check(p1.set_character_kind("mage"), "Ninja can switch back to the existing mage")
	check(is_equal_approx(p1.motor.speed,245.0) and is_equal_approx(p1.motor.jump_speed,460.0), "switching from Ninja to Mage restores original physics")
	check(p1.sprite.texture.get_size() == Vector2(736,736), "Mage art uses the unchanged original 736x736 source")
	check(p1.set_character_kind("ninja"), "Mage can switch back to Ninja")
	check(is_equal_approx(p1.motor.speed,294.0), "repeated character choices do not compound speed multipliers")
	p1.sprite_override = GameplayPlayer.MAGE1
	p1._update_character_sprite(false)
	check(p1.sprite.texture == GameplayPlayer.MAGE1, "legacy one-image Inspector override keeps priority")
	p1.sprite_override = null
	var art: GameplayCharacterVisualSet = GameplayCharacterVisualSet.new()
	art.idle_frames = [wolf.idle_frames[0]]
	p1.character_art_override = art
	p1._update_character_sprite(false)
	check(p1.sprite.texture == wolf.idle_frames[0], "Art Team can override visuals using a standalone Resource")
	p1.character_art_override = null
	# In the playable character scene, either player can switch between all
	# three classes without rebuilding the arena or changing input mappings.
	await tap_character_key(KEY_3)
	check(p1.character_kind == "werewolf" and is_equal_approx(p1.motor.speed, 245.0 * 0.85), "P1 keyboard selection switches Ninja to Werewolf")
	await tap_character_key(KEY_7)
	check(p2.character_kind == "mage" and is_equal_approx(p2.motor.speed, 245.0), "P2 keyboard selection switches Werewolf to Mage")
	await tap_character_key(KEY_2)
	check(p1.character_kind == "ninja" and p1.sprite.texture.get_size() == Vector2(32,32), "P1 can reselect Ninja without losing visual registration")
	# Cover all six shortcuts and repeated changes; child HUD controls must
	# not swallow character selection keys when they have focus.
	for key in [KEY_1, KEY_3, KEY_2, KEY_1, KEY_3, KEY_2]:
		await tap_character_key(key)
		var expected: String = {KEY_1:"mage", KEY_2:"ninja", KEY_3:"werewolf"}[key]
		check(p1.character_kind == expected and p1.sprite.texture != null, "P1 shortcut repeatedly selects %s" % expected)
	for key in [KEY_8, KEY_9, KEY_7]:
		await tap_character_key(key)
		var expected: String = {KEY_7:"mage", KEY_8:"ninja", KEY_9:"werewolf"}[key]
		check(p2.character_kind == expected and p2.sprite.texture != null, "P2 shortcut selects %s" % expected)
	scene.queue_free()
	print("CHARACTER_ART_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
