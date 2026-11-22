## Full two-map visual/skill contract for the three Design characters.
## Uses real physical key events and stores screenshots in /tmp on windowed Mac.
extends SceneTree

var failures: Array[String] = []
var screenshots := 0

func _initialize() -> void:
    call_deferred("_run")

func frames(n: int) -> void:
    for _i in n:
        await physics_frame

func check(ok: bool, label: String) -> void:
    print(("PASS: " if ok else "FAIL: ") + label)
    if not ok:
        failures.append(label)

func key(code: Key, pressed: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func tap(code: Key) -> void:
    key(code, true)
    await frames(2)
    key(code, false)
    await frames(2)

func screenshot(title: String) -> void:
    # Tests run headless too; a real graphical window is required for pixel QA.
    if DisplayServer.get_name() == "headless":
        return
    await RenderingServer.frame_post_draw
    var im := root.get_texture().get_image()
    var path := "/tmp/property_damage_final_" + title + ".png"
    var rc := im.save_png(path)
    check(rc == OK and im.get_width() >= 960, "Capture Mac graphics: " + title)
    print("VISUAL_SCREENSHOT ", path)
    screenshots += 1

func _run() -> void:
    var kinds: Array[String] = ["mage", "ninja", "werewolf"]
    var names: Dictionary = {"mage":"fireball", "ninja":"shuriken",
        "werewolf":"werewolf_unapproved"}
    var maps: Array[String] = ["res://gameplay/garden/garden_level.tscn",
        "res://gameplay/playtest_main.tscn"]
    for map in maps:
        var tag := "garden" if map.contains("garden") else "living"
        for kind in kinds:
            var shell := (load("res://gameplay/integration/two_map_playtest/two_map_playtest.tscn") as PackedScene).instantiate() as Node2D
            var selection: Array[String] = [kind, "mage" if kind != "mage" else "werewolf"]
            shell.selected_kinds = selection
            root.add_child(shell)
            await frames(7)
            shell._on_map_selected(map)
            await frames(9)
            var p1 := shell.arena.get_node("Player1") as GameplayPlayer
            var p2 := shell.arena.get_node("Player2") as GameplayPlayer
            check(p1.character_kind == kind, tag + " actual selection chooses " + kind)
            var design_hp: int = {"mage":120, "ninja":100, "werewolf":160}[kind]
            var design_move: float = {"mage":1.0, "ninja":1.2, "werewolf":0.85}[kind]
            check(p1.health_component.max_hp == design_hp and
                is_equal_approx(p1.motor.speed/p1._base_motor_speed,design_move),
                tag + "/" + kind + " uses Design HP and movement multiplier")
            if kind == "ninja":
                check(p1.motor.jump_speed > p1._base_motor_jump_speed,
                    tag + "/ninja jumps higher than Wizard as Design requires")
            check(p1.sprite.texture != null and p2.sprite.texture != null,
                tag + "/" + kind + " original character textures are available")
            # Verify all Art Team animation frames, not just idle, mirror
            # after character swaps, left/right movement and hurt poses.
            # Art Piskel frames have different native directions:
            # Ninja/Wolf = left at flip_h=false; Mage = right.
            var art_left := kind == "ninja" or kind == "werewolf"
            p1.facing=1
            p1._update_character_sprite(false)
            check(p1.sprite.flip_h == art_left,
                tag + "/" + kind + " idle faces actual right movement")
            p1.facing=-1
            p1._update_character_sprite(true)
            check(p1.sprite.flip_h == not art_left,
                tag + "/" + kind + " animated walk faces actual left movement")
            p1.facing=1
            p1._update_character_sprite(true)
            check(p1.sprite.flip_h == art_left,
                tag + "/" + kind + " running frame turns back right")
            # Include P2, which spawns naturally facing left.
            var p2_art_left := p2.character_kind == "ninja" or p2.character_kind == "werewolf"
            p2.facing=-1
            p2._update_character_sprite(false)
            check(p2.sprite.flip_h == not p2_art_left,
                tag + "/" + kind + " P2 idle faces left")
            p2.facing=1
            p2._update_character_sprite(true)
            check(p2.sprite.flip_h == p2_art_left,
                tag + "/" + kind + " P2 run faces right")
            # Native Art wolf hurt and Ninja fallback hurt pose also
            # respect the source-facing convention after Eva damage.
            p1.health_component.reset()
            p1.health_component.take_damage(1)
            p1.facing=-1
            p1._update_character_sprite(false)
            check(p1.sprite.flip_h == not art_left,
                tag + "/" + kind + " real hurt pose faces source-correct LEFT")
            p1.facing=1
            p1._update_character_sprite(false)
            check(p1.sprite.flip_h == art_left,
                tag + "/" + kind + " real hurt pose faces source-correct RIGHT")
            p1.health_component.reset()
            p1._hurt_pose_seconds=0.0
            p1._update_character_sprite(false)
            # At each map use the same clear real projectile collision lane
            # covered by end-to-end tests, not fabricated direct HP mutation.
            if tag == "garden":
                p1.global_position=Vector2(710,455)
                p2.global_position=Vector2(800,455)
            else:
                p1.global_position=Vector2(430,468)
                p2.global_position=Vector2(520,468)
            p1.velocity=Vector2.ZERO
            p2.velocity=Vector2.ZERO
            p1.facing=1
            p2.facing=-1
            await frames(7)
            var before := p2.health_component.hp
            await tap(KEY_G)
            var bullets: Array[Node] = shell.arena.get_node("Projectiles").get_children()
            check(bullets.size() == 1, tag + "/" + kind + " physical G key creates one attack")
            if bullets.size() > 0:
                var bolt := bullets[0] as GameplayMagicBolt
                check(bolt.projectile_kind == names[kind],
                    tag + "/" + kind + " has correct independent visual category")
            await screenshot(tag + "_" + kind + "_attack")
            await frames(25)
            check(p2.health_component.hp == before - 10,
                tag + "/" + kind + " applies Design 10 damage through real projectile")
            # Both characters keep the shared F/Enter Spark skill in both
            # arenas; no unauthorized character-specific ability invented.
            var signal_counts: Array[int] = [0,0]
            p1.spark.spark_cast.connect(func(_at: Vector2, _accepted: bool) -> void:
                signal_counts[0] += 1)
            p2.spark.spark_cast.connect(func(_at: Vector2, _accepted: bool) -> void:
                signal_counts[1] += 1)
            await tap(KEY_F)
            await tap(KEY_ENTER)
            check(signal_counts == [1,1],tag + "/" + kind +
                " both players' physical Spark keys trigger the existing skill")
            shell.queue_free()
            await frames(3)
    print("ALL_CHARACTER_ART_SKILL_VISUAL_SUMMARY failures=", failures.size(), " screenshots=", screenshots)
    quit(0 if failures.is_empty() else 2)
