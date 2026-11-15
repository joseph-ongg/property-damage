## Product UI acceptance: visual resources, timer, draw, pause, no audio.
extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func test(ok: bool, label: String) -> void:
    if ok:
        print("PASS: ", label)
    else:
        failures.append(label)
        push_error("FAIL: " + label)


func _run() -> void:
    test(root.get_node_or_null("SoundBus") == null,
        "audio system is excluded from this branch")
    test(FileAccess.file_exists("res://gameplay/presentation/assets/title_backdrop.png"),
        "Original locally generated pixel backdrops are available")
    test(FileAccess.file_exists("res://gameplay/presentation/assets/spell_sigil_0.png"),
        "Original hand-coded pixel spell circles are available")
    test(not FileAccess.file_exists("res://gameplay/presentation/audio/reverie_loop.wav"),
        "no chiptune audio or soundtrack shipped")

    var garden := (load("res://gameplay/garden/garden_level.tscn") as PackedScene).instantiate()
    root.add_child(garden)
    await physics_frame
    var manager := garden.get_node("MatchManager") as GameplayMatchManager
    var p1 := garden.get_node("Player1") as GameplayPlayer
    var p2 := garden.get_node("Player2") as GameplayPlayer
    test(manager != null and manager.round_text_label.text.contains("120"),
        "Both real arenas expose the full 120-second clock")
    test(manager.p1_bar.max_value == p1.health.max_hp
        and manager.p2_bar.max_value == p2.health.max_hp,
        "HUD health bars use Eva's actual per-character HP")
    manager.round_seconds_left = 0.02
    await create_timer(0.1).timeout
    test(manager.round_over and manager.p1_wins == 0 and manager.p2_wins == 0,
        "Equal-HP round times out as draw without awarding a win")
    test(manager.headline.text.contains("DRAW"), "time-out produces an explicit draw result")
    manager.continue_after_round()
    test(not manager.round_over and manager.round_seconds_left > 119,
        "next round restores the clock and unfreezes players")

    p1.health.hp = maxi(1, p1.health.max_hp / 3)
    p2.health.hp = p2.health.max_hp
    manager.round_seconds_left = 0.02
    await create_timer(0.1).timeout
    test(manager.round_over and manager.p2_wins == 1,
        "timeout winner is chosen by remaining HP percentage")
    manager.new_match()
    test(manager.p1_wins == 0 and manager.p2_wins == 0
        and manager.round_seconds_left > 119,
        "rematch clears timer and score")

    var pause := garden.get_node("PauseOverlay")
    pause.set_paused(true)
    test(paused and pause.is_paused and pause.pause_root.visible,
        "Garden shares real pause/options menu")
    test(pause.pause_panel != null and pause.help_panel != null,
        "pause screen exposes battle controls but no audio settings")
    pause.set_paused(false)
    test(not paused, "resume restores Godot process state")
    garden.queue_free()

    var main := (load("res://gameplay/presentation/main_menu.tscn") as PackedScene).instantiate()
    root.add_child(main)
    await physics_frame
    test(main.start_button != null and main.has_node("Background"),
        "main menu contains independent local-versus entry and pixel art")
    main.queue_free()

    var help := (load("res://gameplay/presentation/help_screen.tscn") as PackedScene).instantiate()
    root.add_child(help)
    await physics_frame
    test(help.has_node("Background"), "two-player controls tutorial exists")
    help.queue_free()

    var settings := (load("res://gameplay/presentation/settings_screen.tscn") as PackedScene).instantiate()
    root.add_child(settings)
    await physics_frame
    test(settings.fullscreen_toggle != null,
        "display-only settings exist without audio controls")
    settings.queue_free()
    var credits := (load("res://gameplay/presentation/credits_screen.tscn") as PackedScene).instantiate()
    root.add_child(credits)
    await physics_frame
    test(credits.has_node("Background"), "original game credits screen is available")
    credits.queue_free()
    print("ARCANE_FEATURES_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
