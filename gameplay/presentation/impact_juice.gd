## Reusable feedback on top of *existing* Health and item damage signals.
## Screen shake, small Godot-drawn hit particles and 65ms slow-motion hit-stop.
## No image generator, audio, extra damage state or Simulation changes.
extends Node2D

@export var camera_center: Vector2 = Vector2(480, 270)
var camera: Camera2D
var shake_time: float = 0.0
var freeze_until_msec: int = 0
var specks: Array[Dictionary] = []
var _prng := RandomNumberGenerator.new()


func _ready() -> void:
    z_index = 24
    process_mode = Node.PROCESS_MODE_ALWAYS
    _prng.seed = 18731
    camera = Camera2D.new()
    camera.name = "HitCamera"
    camera.position = camera_center
    camera.enabled = true
    camera.ignore_rotation = true
    add_child(camera)
    camera.make_current()
    call_deferred("_wire_damage_signals")


func _wire_damage_signals() -> void:
    var arena := get_parent()
    for player_number in 2:
        var player := arena.get_node_or_null("Player%d" % (player_number + 1)) as GameplayPlayer
        if player != null:
            player.health.damaged.connect(_on_player_hit.bind(player))
    for item in get_tree().get_nodes_in_group("interactable_items"):
        if item is GameplayInteractableItem and arena.is_ancestor_of(item):
            (item as GameplayInteractableItem).damaged.connect(_on_item_hit.bind(item))


func _on_player_hit(_amount: int, player: GameplayPlayer) -> void:
    impact(player.global_position + Vector2(0, -26), Color("#f6b3d1"), true)


func _on_item_hit(_amount: float, _player_index: int, item: GameplayInteractableItem) -> void:
    impact(item.global_position, Color("#f2cd89"), false)


func impact(pos: Vector2, tint: Color, heavy: bool = false) -> void:
    shake_time = maxf(shake_time, 0.17 if heavy else 0.09)
    for i in (15 if heavy else 8):
        var angle := _prng.randf_range(0, TAU)
        var speed := _prng.randf_range(70.0, 210.0 if heavy else 135.0)
        specks.append({
            "pos": pos + Vector2(_prng.randf_range(-4, 4), _prng.randf_range(-4, 4)),
            "vel": Vector2(cos(angle) * speed, sin(angle) * speed),
            "life": _prng.randf_range(0.18, 0.36),
            "tint": tint,
        })
    if heavy and DisplayServer.get_name() != "headless" and not get_tree().paused:
        if Engine.time_scale == 1.0:
            Engine.time_scale = 0.24
            freeze_until_msec = Time.get_ticks_msec() + 65
    queue_redraw()


func _process(delta: float) -> void:
    if freeze_until_msec > 0 and Time.get_ticks_msec() >= freeze_until_msec:
        Engine.time_scale = 1.0
        freeze_until_msec = 0
    var real_delta := delta / maxf(0.05, Engine.time_scale)
    shake_time = maxf(0.0, shake_time - real_delta)
    camera.offset = Vector2(
        _prng.randf_range(-5.0, 5.0),
        _prng.randf_range(-3.0, 3.0)) if shake_time > 0.0 else Vector2.ZERO
    for particle in specks:
        particle["pos"] = particle["pos"] + (particle["vel"] as Vector2) * real_delta
        particle["vel"] = (particle["vel"] as Vector2) + Vector2(0, 180 * real_delta)
        particle["life"] = float(particle["life"]) - real_delta
    specks = specks.filter(func(v: Dictionary) -> bool: return float(v["life"]) > 0.0)
    if specks.size() > 0:
        queue_redraw()


func _draw() -> void:
    for particle in specks:
        var pos: Vector2 = particle["pos"]
        var lifespan: float = particle["life"]
        draw_rect(Rect2(pos, Vector2(4, 4) if lifespan > 0.12 else Vector2(2, 2)),
            particle["tint"] as Color, true)


func _exit_tree() -> void:
    if freeze_until_msec > 0:
        Engine.time_scale = 1.0
