## Garden-specific interactable mechanics:
## tree holes = crouch cover; hose = extinguish Simulation grid;
## gnomes = shootable fragile items; flying birds = dodgeable droppings.
## Rendered by Godot drawing primitives and original Art Team bird pixel frames.
extends Node2D

const BIRD_FRAMES: Array[Texture2D] = [
    preload("res://gameplay/art_team/exported/bird_drop_0.png"),
    preload("res://gameplay/art_team/exported/bird_drop_1.png"),
    preload("res://gameplay/art_team/exported/bird_drop_2.png"),
]
const HOSE := Vector2(131, 468)
const HOLES := [Vector2(685, 441), Vector2(814, 441)]
const BIRD_HEIGHT := 134.0

var bird_x: float = 115.0
var bird_direction: float = 1.0
var bird_clock: float = 0.0
var next_drop: float = 3.4
var bird_drops: Array[Dictionary] = []
var hose_time: float = 0.0
var hose_cooldown: float = 0.0
var hose_tick: float = 0.0
var hose_dir: int = 1
var cover_players: Array[int] = []

@onready var arena: Node2D = get_parent() as Node2D
@onready var grid: MaterialGrid = arena.get_node("MaterialGrid") as MaterialGrid
var tree_prop: GameplayGardenProp
@onready var manager: GameplayMatchManager = arena.get_node("MatchManager") as GameplayMatchManager


func _ready() -> void:
    z_index = 12
    call_deferred("_bind_tree")


func _bind_tree() -> void:
    tree_prop = arena.get_node_or_null("GardenItems/Tree") as GameplayGardenProp
    for index in 2:
        var gnome := GameplayGardenGnome.new()
        gnome.name = "Gnome%d" % (index + 1)
        gnome.position = Vector2(350.0 + float(index) * 310.0, 454.0)
        gnome.destroyed.connect(_on_gnome_destroyed.bind(gnome))
        arena.get_node("GardenItems").add_child(gnome)
    for i in 2:
        var player := arena.get_node("Player%d" % (i + 1)) as GameplayPlayer
        player.interact_pressed.connect(_on_interact)


func _on_gnome_destroyed(who: int, _gnome: GameplayGardenGnome) -> void:
    if who in [1, 2]:
        (arena.get_node("Player%d" % who) as GameplayPlayer).reward_destruction()


func _on_interact(_number: int, player: GameplayPlayer) -> void:
    if manager.round_over:
        return
    if player.global_position.distance_to(HOSE) <= 92.0 and hose_cooldown <= 0.0:
        hose_dir = player.facing
        hose_time = 4.5
        hose_cooldown = 10.0
        hose_tick = 0.0
        queue_redraw()


func _physics_process(delta: float) -> void:
    if manager.round_over or tree_prop == null:
        return
    _update_cover()
    hose_time = maxf(0.0, hose_time - delta)
    hose_cooldown = maxf(0.0, hose_cooldown - delta)
    hose_tick -= delta
    if hose_time > 0.0 and hose_tick <= 0.0:
        hose_tick = 0.13
        _extinguish_hose()
    bird_clock += delta
    bird_x += bird_direction * delta * 53.0
    if bird_x > 891.0:
        bird_x = 891.0
        bird_direction = -1.0
    elif bird_x < 72.0:
        bird_x = 72.0
        bird_direction = 1.0
    next_drop -= delta
    if next_drop <= 0.0:
        next_drop = 4.6
        bird_drops.append({
            "position": Vector2(bird_x, BIRD_HEIGHT + 22),
            "velocity": 105.0,
            "hit": false,
        })
    for drop in bird_drops:
        drop["position"] = drop["position"] + Vector2(0.0, float(drop["velocity"]) * delta)
        drop["velocity"] = minf(310.0, float(drop["velocity"]) + 260.0 * delta)
        var pos: Vector2 = drop["position"]
        if pos.y >= 469.0 or bool(drop["hit"]):
            continue
        for index in 2:
            var target := arena.get_node("Player%d" % (index + 1)) as GameplayPlayer
            if pos.distance_to(target.global_position + Vector2(0, -27)) < 19.0:
                target.take_damage(7.0)
                drop["hit"] = true
                break
    bird_drops = bird_drops.filter(func(d: Dictionary) -> bool:
        return (d["position"] as Vector2).y < 486.0 and not bool(d["hit"]))
    queue_redraw()


func _update_cover() -> void:
    cover_players.clear()
    for index in 2:
        var player_number := index + 1
        var player := arena.get_node("Player%d" % player_number) as GameplayPlayer
        var down := Input.is_action_pressed("p%d_down" % player_number)
        var inside := false
        if not tree_prop.destroyed_item and down:
            for hole in HOLES:
                if player.global_position.distance_to(hole) <= 52.0:
                    inside = true
        player.in_cover = inside
        if inside:
            cover_players.append(player_number)


func _extinguish_hose() -> void:
    # Use upstream MaterialGrid's public extinguish API, not a second grid.
    var direction := hose_dir
    for xstep in 15:
        for ystep in 3:
            var pos := HOSE + Vector2(float(xstep * 16 * direction), float(ystep * 16 - 34))
            var cell := grid.world_to_cell(pos)
            if grid.in_bounds(cell.x, cell.y) and grid.is_burning(cell.x, cell.y):
                grid.extinguish(cell.x, cell.y)


func reset_mechanics() -> void:
    bird_x = 115.0
    bird_direction = 1.0
    bird_clock = 0.0
    next_drop = 3.4
    bird_drops.clear()
    hose_time = 0.0
    hose_cooldown = 0.0
    hose_tick = 0.0
    cover_players.clear()
    for index in 2:
        (arena.get_node("Player%d" % (index + 1)) as GameplayPlayer).in_cover = false
    queue_redraw()


func _draw() -> void:
    # Hose nozzle, water droplets and pressure stream.
    draw_rect(Rect2(HOSE + Vector2(-16, -5), Vector2(25, 8)), Color("#4a9dad"))
    draw_rect(Rect2(HOSE + Vector2(7, -10), Vector2(9, 13)), Color("#bbcfd7"))
    if hose_time > 0.0:
        for i in 17:
            var dot := HOSE + Vector2(float(i * 15 * hose_dir),
                -26 + sin(float(i * 2) + bird_clock * 22.0) * 9.0)
            draw_rect(Rect2(dot, Vector2(5, 3)), Color("#85e2f4"))
    if hose_cooldown <= 0.0:
        draw_string(ThemeDB.fallback_font, HOSE + Vector2(-40, -19),
            "E / SHIFT: HOSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#bcf1f6"))
    # Tree hollows are cover only while a living trunk exists.
    if tree_prop != null and not tree_prop.destroyed_item:
        for hole in HOLES:
            draw_ellipse_outline(hole, Color("#27233b"))
        for player_number in cover_players:
            var player := arena.get_node("Player%d" % player_number) as GameplayPlayer
            draw_rect(Rect2(player.global_position + Vector2(-18, -65), Vector2(40, 10)),
                Color("#2e3b5e"), true)
            draw_string(ThemeDB.fallback_font, player.global_position + Vector2(-16, -57),
                "HIDDEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e7dbb6"))
    var bird_frame: Texture2D = BIRD_FRAMES[int(bird_clock * 7.0) % BIRD_FRAMES.size()]
    draw_texture_rect(bird_frame, Rect2(bird_x - 21, BIRD_HEIGHT - 14, 42, 42), false)
    for drop in bird_drops:
        var p: Vector2 = drop["position"]
        draw_rect(Rect2(p + Vector2(-4, -4), Vector2(8, 8)), Color("#e3f0df"))
        draw_rect(Rect2(p + Vector2(-1, -8), Vector2(2, 4)), Color("#c2d0c8"))


func draw_ellipse_outline(at: Vector2, tint: Color) -> void:
    draw_arc(at, 18, 0.0, TAU, 25, tint, 4.0)
    draw_rect(Rect2(at + Vector2(-9, 8), Vector2(18, 7)), Color("#363349"))
