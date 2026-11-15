## Art & Audio Piskel integration: provenance, PNG frames, live resource wiring.
extends SceneTree

var failures: Array[String] = []


func check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: ", description)
    else:
        failures.append(description)
        push_error("FAIL: " + description)


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var source_dir := "res://gameplay/art_team/source/"
    var exported := "res://gameplay/art_team/exported/"
    var catalog_path := "res://gameplay/art_team/catalog.json"
    check(FileAccess.file_exists(catalog_path), "Piskel asset manifest is present")
    var catalog = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
    check(catalog is Array and catalog.size() == 14, "all fourteen Art Team Piskel sources are catalogued")
    var count := 0
    for item in catalog:
        check(FileAccess.file_exists(source_dir + item["original_name"]), "preserved Art source: " + item["original_name"])
        for filename in item["exports"]:
            var texture := load(exported + filename) as Texture2D
            check(texture != null and texture.get_size() == Vector2(item["frame_size"][0], item["frame_size"][1]),
                "original frame exported at native resolution: " + filename)
            count += 1
    check(count == 25, "all 25 original Art Team raster frames are exported")

    var ninja := load("res://gameplay/characters/ninja_visuals.tres") as GameplayCharacterVisualSet
    var wolf := load("res://gameplay/characters/werewolf_visuals.tres") as GameplayCharacterVisualSet
    var mage := load("res://gameplay/art_team/mage_visuals.tres") as GameplayCharacterVisualSet
    check(ninja != null and ninja.run_frames.size() == 4 and is_equal_approx(ninja.run_fps, 12.0),
        "live Ninja uses Art Team four-frame walk at native FPS")
    check(wolf != null and wolf.run_frames.size() == 2 and is_equal_approx(wolf.run_fps, 7.0),
        "live Werewolf uses Art Team two-frame walk at native FPS")
    check(ninja.idle_frames[0].resource_path == exported + "ninja_side_0.png",
        "live Ninja idle comes from Art Team Piskel")
    check(wolf.hurt_texture.resource_path == exported + "wolf_damage_1.png",
        "live Werewolf hurt pose comes from Art Team Piskel")
    check(mage != null and mage.idle_frames[0].resource_path == exported + "mage_idle_0.png",
        "optional Art Team Mage profile is usable without replacing original Mage")

    var garden := (load("res://gameplay/LevelSelection/GardenPlaceholder.tscn") as PackedScene).instantiate()
    root.add_child(garden)
    check((garden.get_node("Sprite2D") as Sprite2D).texture.resource_path == exported + "garden.png",
        "Angela's Garden placeholder uses latest Art Team background")
    check(garden.has_node("Backtomenu") and garden.has_node("ArtPreviewNotice"),
        "Garden preview retains Angela's navigation and identifies itself as preview")
    garden.queue_free()

    var gallery := (load("res://gameplay/art_team/art_gallery.tscn") as PackedScene).instantiate()
    root.add_child(gallery)
    await process_frame
    check(gallery.map_image.texture.resource_path == exported + "living_room_map.png",
        "optional gallery shows full original Living Room map")
    gallery._switch_map()
    check(gallery.map_image.texture.resource_path == exported + "garden.png",
        "optional gallery can switch to full original Garden map")
    gallery.queue_free()

    var arena := (load("res://gameplay/msd/gameplay_msd.tscn") as PackedScene).instantiate()
    root.add_child(arena)
    await physics_frame
    var player1 := arena.get_node("Player1") as GameplayPlayer
    var player2 := arena.get_node("Player2") as GameplayPlayer
    check(player1.set_character_kind("ninja") and player2.set_character_kind("werewolf"),
        "new Art Team visuals load into actual two-player arena")
    check(player1.sprite.texture == ninja.idle_frames[0] and player2.sprite.texture == wolf.idle_frames[0],
        "both real player sprite nodes render Art Team frames")
    check(player1.health.max_hp == 100 and player2.health.max_hp == 160,
        "art swap preserves Gameplay character stats and Eva's Health component")
    check(arena.get_node("FireVisuals").use_art_team_flame,
        "live fire VFX uses Art Team flame sprite without changing Simulation")
    arena.queue_free()

    print("ART_TEAM_INTEGRATION_SUMMARY failures=", failures.size())
    quit(0 if failures.is_empty() else 1)
