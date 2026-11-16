## Telegraphing sentry beam + meteor fragments; no borrowed sound or art.
extends Node2D

const BEAM_Y := 419.0
var cycle_age: float = 0.0
var damage_cooldowns: Array[float] = [0.0, 0.0]
var meteors: Array[Dictionary] = []
var meteor_age: float = 2.8
var fired_count: int = 0
@onready var arena: Node2D = get_parent() as Node2D
@onready var manager: GameplayMatchManager = arena.get_node("MatchManager") as GameplayMatchManager
@onready var grid: MaterialGrid = arena.get_node("MaterialGrid") as MaterialGrid


func _ready() -> void:
    z_index = 13


func _physics_process(delta: float) -> void:
    if manager.round_over:
        return
    cycle_age = fmod(cycle_age + delta, 7.0)
    for i in 2:
        damage_cooldowns[i] = maxf(0.0, damage_cooldowns[i] - delta)
    var active := cycle_age >= 4.1 and cycle_age < 5.45
    if active:
        for i in 2:
            var player := arena.get_node("Player%d" % (i+1)) as GameplayPlayer
            if player.global_position.y >= BEAM_Y - 17 and player.global_position.y <= BEAM_Y + 30 and damage_cooldowns[i] == 0.0:
                player.take_damage(12.0)
                damage_cooldowns[i] = 0.9
    meteor_age -= delta
    if meteor_age <= 0.0:
        meteor_age = 3.7
        fired_count += 1
        meteors.append({
            "position": Vector2(160 + ((fired_count * 143) % 630), 98),
            "speed": 145.0,
            "alive": true,
        })
    for meteor in meteors:
        var pos: Vector2 = meteor["position"]
        pos += Vector2(-65.0, float(meteor["speed"])) * delta
        meteor["speed"] = minf(340.0, float(meteor["speed"]) + 230.0 * delta)
        meteor["position"] = pos
        if pos.y > 478 or not bool(meteor["alive"]):
            continue
        for i in 2:
            var player := arena.get_node("Player%d" % (i + 1)) as GameplayPlayer
            if pos.distance_to(player.global_position + Vector2(0, -24)) < 23.0:
                player.take_damage(10.0)
                meteor["alive"] = false
        if pos.y >= 470:
            var cell := grid.world_to_cell(pos)
            if grid.in_bounds(cell.x, cell.y):
                grid.ignite(cell.x, cell.y)
            meteor["alive"] = false
    meteors = meteors.filter(func(m: Dictionary) -> bool:
        return bool(m["alive"]) and (m["position"] as Vector2).y < 475)
    queue_redraw()


func reset_mechanics() -> void:
    cycle_age = 0.0
    meteors.clear()
    meteor_age = 2.8
    fired_count = 0
    damage_cooldowns = [0.0, 0.0]
    queue_redraw()


func _draw() -> void:
    var active := cycle_age >= 4.1 and cycle_age < 5.45
    var warning := cycle_age >= 3.35 and cycle_age < 4.1
    # HUD stays at top; beam telegraphs in-world before firing.
    if active:
        draw_rect(Rect2(Vector2(26, BEAM_Y - 6), Vector2(908, 12)),
            Color(1.0, 0.35, 0.69, 0.70))
        draw_line(Vector2(26, BEAM_Y), Vector2(934, BEAM_Y),
            Color("#f8ecdd"), 4.0)
    elif warning:
        draw_line(Vector2(26, BEAM_Y), Vector2(934, BEAM_Y),
            Color("#f4b0ce"), 2.0)
    for x in [26.0, 934.0]:
        draw_arc(Vector2(x, BEAM_Y), 13, 0.0, TAU, 22,
            Color("#f7d58b") if active else Color("#9faad9"), 2.0)
    for meteor in meteors:
        var pos: Vector2 = meteor["position"]
        draw_line(pos + Vector2(10, -26), pos + Vector2(-4, 5),
            Color("#ecb0de"), 4.0)
        draw_rect(Rect2(pos + Vector2(-6, -5), Vector2(12, 10)),
            Color("#fbe9cb"))
