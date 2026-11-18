## Garden-only implementation of the existing Design document.
## Reuses GameplayPlayer, Eva's Health, main's prop-flight helper and
## Ethan's public MaterialGrid API; does not edit their source files.
extends Node2D

const BIRD_FRAMES: Array[Texture2D] = [
    preload("res://gameplay/art_team/exported/bird_drop_0.png"),
    preload("res://gameplay/art_team/exported/bird_drop_1.png"),
    preload("res://gameplay/art_team/exported/bird_drop_2.png")
]

# World coords derived from original 426x286 Garden Piskel at x2,
# offset (54,-16). Tree drawing has high and low brown hollow entrances.
const TREE_LOWER := Vector2(752, 423)
const TREE_UPPER := Vector2(756, 146)
const TREE_LOWER_EXIT := Vector2(752, 440)
const TREE_UPPER_EXIT := Vector2(700, 232)
const HOSE_ART_ORIGIN := Vector2(580, 465)

# Document says "occasionally" without an interval; keep tuning editable.
@export_range(1.0, 30.0, 0.1) var bird_drop_interval: float = 5.0
# Design has "(?)" on hose damage. Playable 1HP/s default, inspector toggle
# allows Design to reject it without changing Austin/Eva code.
@export var tentative_hose_damage_enabled: bool = true
@export var hose_duration_seconds: float = 10.0
@export var hose_damage_per_second: int = 1

var _bird: Sprite2D
var _hose_end: GameplayGardenThrowable
var _bird_time: float = 0.0
var _bird_drop_timer: float = 0.0
var apples_dropped: int = 0
var _hose_owner: GameplayPlayer = null
var hose_seconds_left: float = 0.0
var _hose_damage_clock: float = 0.0
var _portal_cooldown: Dictionary = {}
var _held_throwables: Dictionary = {}
var _initial_throwable_positions: Dictionary = {}
var last_action: String = ""
var _initial_grid_materials: Array[Array] = []
var _fence_burn_elapsed: Dictionary = {}
var _fence_occupied_cells: Dictionary = {}
var _destroyed_by_player := {1: 0, 2: 0}
var _fractional_damage_by_player := {1: 0.0, 2: 0.0}

@onready var arena: Node2D = get_parent() as Node2D
@onready var grid: MaterialGrid = arena.get_node("MaterialGrid") as MaterialGrid


func _ready() -> void:
    _bird_drop_timer = bird_drop_interval
    for idx in 8:
        var fence := GameplayGardenFenceSegment.new()
        fence.name = "Fence%02d" % (idx + 1)
        fence.segment_index = idx
        arena.get_node("Fences").add_child(fence)
        fence.damaged.connect(_on_fence_damaged)
        fence.destroyed.connect(_on_fence_destroyed)
        _fence_burn_elapsed[idx] = 0.0
    for index in [1, 2]:
        (arena.get_node("Player%d" % index) as GameplayPlayer).interact_pressed.connect(_on_player_interact)
    for rose in [
        {"name":"LeftRoseThorns","at":Vector2(100, 397),"size":Vector2(47, 154)},
        {"name":"RightRoseThorns","at":Vector2(369, 404),"size":Vector2(40, 137)}
    ]:
        _make_rose_contact(rose)
    # Two source-matched mushroom tokens and two temporary gnomes.
    _make_throwable(GameplayGardenThrowable.Kind.MUSHROOM, Vector2(417, 435), "Mushrooms1", 0)
    _make_throwable(GameplayGardenThrowable.Kind.MUSHROOM, Vector2(477, 435), "Mushrooms2", 1)
    _make_throwable(GameplayGardenThrowable.Kind.GNOME, Vector2(311, 452), "Gnome1")
    _make_throwable(GameplayGardenThrowable.Kind.GNOME, Vector2(648, 452), "Gnome2")
    # The nozzle is both a pick-up-able sprayer and an Austin-compatible
    # throwable. Visual pixels come directly from the Art Team Garden.
    _hose_end = _make_throwable(GameplayGardenThrowable.Kind.HOSE_END,
        HOSE_ART_ORIGIN, "HoseEnd")
    _bird = Sprite2D.new()
    _bird.name = "ArtTeamBird"
    _bird.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _bird.scale = Vector2(1.6, 1.6)
    _bird.texture = BIRD_FRAMES[0]
    _bird.position = Vector2(664, 128)
    add_child(_bird)
    _seed_source_fuel()
    _capture_original_grid()


func _make_rose_contact(spec: Dictionary) -> void:
    var rose := Area2D.new()
    rose.name = str(spec["name"])
    rose.position = spec["at"]
    rose.collision_layer = 0
    rose.collision_mask = 2  # players only
    var shape := RectangleShape2D.new()
    shape.size = spec["size"]
    var hitbox := CollisionShape2D.new()
    hitbox.shape = shape
    rose.add_child(hitbox)
    arena.get_node("RoseThorns").add_child(rose)
    rose.body_entered.connect(_on_rose_body_entered)


func _on_rose_body_entered(body: Node2D) -> void:
    var player := body as GameplayPlayer
    if player == null:
        return
    # Design: EXACTLY five damage on thorn contact. Eva controls invulnerability.
    if player.health_component.take_damage(5):
        _show_status("P%d • ROSE THORNS: -5 HP" % player.player_index)


func _on_fence_damaged(segment: int, remaining_hp: int, attacker: int) -> void:
    _show_status("P%d • FENCE %d  %d/4 HP" % [attacker, segment, remaining_hp])


## Design: destroying a property awards 5% to the attack multiplier.
## Eva stores integer HP, so retain fractional damage for later attacks:
## 10.5 + 10.5 applies 10 + 11, not 10 + 10 or 11 + 11.
func _on_fence_destroyed(_segment: int, attacker: int) -> void:
    if not _destroyed_by_player.has(attacker):
        return
    _destroyed_by_player[attacker] += 1
    _show_status("P%d • PROPERTY DESTROYED • +5%% ATTACK" % attacker)


func damage_for_player_attack(attacker: int) -> int:
    var bonus: float = float(_destroyed_by_player.get(attacker, 0)) * 0.05
    var amount: float = 10.0 * (1.0 + bonus) + float(_fractional_damage_by_player.get(attacker, 0.0))
    var whole := floori(amount + 0.00001)
    _fractional_damage_by_player[attacker] = amount - float(whole)
    return whole


func _capture_original_grid() -> void:
    _initial_grid_materials.clear()
    for x in grid.width:
        var column: Array = []
        for y in grid.height:
            column.append(grid.get_cell_material(x,y))
        _initial_grid_materials.append(column)


func _restore_original_grid() -> void:
    # Restore every cell, not only the handful of painted wood points.
    # This clears residual burning/ash after a round even at arbitrary
    # cells while leaving Ethan's MaterialGrid storage untouched.
    for x in grid.width:
        for y in grid.height:
            grid.set_cell_material(x, y, _initial_grid_materials[x][y])


func _make_throwable(kind: GameplayGardenThrowable.Kind, at: Vector2, label: String,
        mushroom_index: int = 0) -> GameplayGardenThrowable:
    var item := GameplayGardenThrowable.new()
    item.name = label
    item.kind = kind
    item.mushroom_source_index = mushroom_index
    item.position = at
    arena.get_node("Throwables").add_child(item)
    _initial_throwable_positions[label] = at
    return item


func _seed_source_fuel() -> void:
    # Ethan's existing grid is the ONLY fire store. This only registers
    # the original painted tree/rose/fence as wood at a handful of points.
    for point in [Vector2(188, 359), Vector2(357, 334),
        Vector2(711, 294), Vector2(755, 394), Vector2(665, 195)]:
        _set_wood_at(point)
    for segment in arena.get_node("Fences").get_children():
        var fence := segment as GameplayGardenFenceSegment
        var footprint := fence.occupied_fire_cells(grid)
        _fence_occupied_cells[fence.segment_index] = footprint
        for cell: Vector2i in footprint:
            grid.set_cell_material(cell.x, cell.y, MaterialGrid.Materials.WOOD)


func _set_wood_at(world: Vector2) -> void:
    var cell := grid.world_to_cell(world)
    if grid.in_bounds(cell.x, cell.y):
        grid.set_cell_material(cell.x, cell.y, MaterialGrid.Materials.WOOD)


func _on_player_interact(player_index: int, player: GameplayPlayer) -> void:
    if not is_instance_valid(player):
        return
    if _try_tree_hole(player_index, player):
        return
    if _hose_owner == player:
        if is_instance_valid(_hose_end):
            _hose_end.throw_from(player)
        _release_hose()
        _show_status("P%d • THREW HOSE END" % player_index)
        return
    # Existing held items get thrown before another item is picked up.
    var carried := _held_throwables.get(player_index) as GameplayGardenThrowable
    if is_instance_valid(carried) and carried.carried_by == player:
        if carried.throw_from(player):
            _held_throwables.erase(player_index)
            _show_status("P%d • THREW %s" % [player_index, carried.name])
        return
    if _hose_owner == null and is_instance_valid(_hose_end) and _hose_end.can_pick_up(player):
        if _hose_end.pick_up(player):
            _hose_owner = player
            hose_seconds_left = hose_duration_seconds
            _hose_damage_clock = 0.0
            _show_status("P%d • WATER HOSE • 10s" % player_index)
        return
    var nearest: GameplayGardenThrowable = null
    var best_distance := INF
    for item: GameplayGardenThrowable in arena.get_node("Throwables").get_children():
        if not item.can_pick_up(player):
            continue
        var distance := item.global_position.distance_to(player.global_position)
        if distance < best_distance:
            best_distance = distance
            nearest = item
    if nearest != null and nearest.pick_up(player):
        _held_throwables[player_index] = nearest
        _show_status("P%d • PICKED UP %s" % [player_index, nearest.name])


func _try_tree_hole(index: int, player: GameplayPlayer) -> bool:
    if float(_portal_cooldown.get(index, 0.0)) > 0.0:
        return false
    var near_bottom := player.global_position.distance_to(TREE_LOWER) < 79.0
    var near_top := player.global_position.distance_to(TREE_UPPER_EXIT) < 75.0
    if not near_bottom and not near_top:
        return false
    player.global_position = TREE_UPPER_EXIT if near_bottom else TREE_LOWER_EXIT
    player.velocity = Vector2.ZERO
    player.motor.reset()
    _portal_cooldown[index] = 0.55
    _show_status("P%d • TREE HOLE %s" % [index, "UP" if near_bottom else "DOWN"])
    return true


func _physics_process(delta: float) -> void:
    for index in _portal_cooldown.keys():
        _portal_cooldown[index] = maxf(0.0, float(_portal_cooldown[index]) - delta)
    _tick_fence_fire(delta)
    _bird_time += delta
    if _bird != null:
        _bird.texture = BIRD_FRAMES[int(_bird_time * 7.0) % BIRD_FRAMES.size()]
        # Bird visibly departs from the Art Team's tree, then returns.
        _bird.position = Vector2(664.0 + 165.0 * sin(_bird_time * 0.45),
            124.0 + 11.0 * sin(_bird_time * 1.2))
    _bird_drop_timer -= delta
    if _bird_drop_timer <= 0.0:
        _bird_drop_timer += bird_drop_interval
        _drop_apple()
    if _hose_owner != null:
        hose_seconds_left = maxf(0.0, hose_seconds_left - delta)
        if hose_seconds_left <= 0.0 or not is_instance_valid(_hose_owner):
            _release_hose()
        else:
            _hose_spray(delta)
            queue_redraw()


## Design: all properties are flammable, and sustained fire removes 1 HP
## every 3 seconds. Reuse the active Ethan cell state; do not invent a
## second fire simulation. This rule is scoped to Garden-owned fences.
func _tick_fence_fire(delta: float) -> void:
    for fence: GameplayGardenFenceSegment in arena.get_node("Fences").get_children():
        var index := fence.segment_index
        if fence.destroyed_segment:
            _fence_burn_elapsed[index] = 0.0
            continue
        var any_fire := false
        for cell: Vector2i in _fence_occupied_cells.get(index, []):
            if grid.is_burning(cell.x, cell.y):
                any_fire = true
                break
        if not any_fire:
            _fence_burn_elapsed[index] = 0.0
            continue
        var duration := float(_fence_burn_elapsed.get(index, 0.0)) + delta
        while duration >= 3.0 and not fence.destroyed_segment:
            duration -= 3.0
            fence.take_hit(0)  # ignition owner is unknown: no guessed PVP bonus
        _fence_burn_elapsed[index] = duration


func _drop_apple() -> void:
    if _bird == null:
        return
    # Limit ordinary uncollected objects, never delete a player's held item.
    var apples := 0
    for item: GameplayGardenThrowable in arena.get_node("Throwables").get_children():
        if item.kind == GameplayGardenThrowable.Kind.APPLE:
            if item.consumed:
                item.queue_free()  # do not exhaust the apple cap with invisible hits
                continue
            apples += 1
    if apples >= 6:
        # "Occasionally drops apples" must continue throughout a round.
        # Recycle the oldest unheld apple instead of letting the bird stop
        # forever. Never delete an apple currently carried by either player.
        var recyclable: GameplayGardenThrowable = null
        for item: GameplayGardenThrowable in arena.get_node("Throwables").get_children():
            if item.kind == GameplayGardenThrowable.Kind.APPLE and not item.consumed and item.carried_by == null:
                recyclable = item
                break
        if recyclable == null:
            return  # both players holding apples: preserve ownership
        recyclable.queue_free()
    var apple := _make_throwable(GameplayGardenThrowable.Kind.APPLE,
        _bird.position + Vector2(0, 26), "Apple%02d" % (apples_dropped + 1))
    apple.flying = true
    apple.flight_velocity = Vector2(0, 84)
    _initial_throwable_positions.erase(apple.name)
    apples_dropped += 1


func _hose_spray(delta: float) -> void:
    var at := _hose_origin()
    var facing := float(_hose_owner.facing)
    var finish := at + Vector2(facing * 192.0, -12.0)
    for step in range(15):
        var p := at.lerp(finish, float(step) / 14.0)
        var cell := grid.world_to_cell(p)
        if grid.in_bounds(cell.x, cell.y) and grid.is_burning(cell.x, cell.y):
            grid.extinguish(cell.x, cell.y)  # upstream API, never duplicate fire grid
    if not tentative_hose_damage_enabled:
        return
    _hose_damage_clock += delta
    if _hose_damage_clock < 1.0:
        return
    _hose_damage_clock -= 1.0
    var other_index := 2 if _hose_owner.player_index == 1 else 1
    var other := arena.get_node("Player%d" % other_index) as GameplayPlayer
    var forward_distance := (other.global_position.x - at.x) * facing
    if forward_distance >= 0.0 and forward_distance <= 192.0 and absf(other.global_position.y - at.y) <= 35.0:
        other.health_component.take_damage(hose_damage_per_second)


func _hose_origin() -> Vector2:
    if _hose_owner == null:
        return HOSE_ART_ORIGIN
    return _hose_owner.global_position + Vector2(float(_hose_owner.facing) * 26.0, -22.0)


func _release_hose() -> void:
    if is_instance_valid(_hose_end) and _hose_end.carried_by != null:
        # The original 10-second Design window is over. The hose head
        # drops through the shared prop physics unless E/Shift threw it.
        _hose_end.carried_by = null
        _hose_end.flying = true
        _hose_end.flight_velocity = Vector2.ZERO
    _hose_owner = null
    hose_seconds_left = 0.0
    _hose_damage_clock = 0.0
    queue_redraw()


## Optional handoff for Angela's round/rematch controller: restore this
## Garden's local destructibles and items without modifying her loop.
func reset_garden_for_round() -> void:
    for fence: GameplayGardenFenceSegment in arena.get_node("Fences").get_children():
        fence.restore()
    for item: GameplayGardenThrowable in arena.get_node("Throwables").get_children():
        if item.kind == GameplayGardenThrowable.Kind.APPLE:
            item.queue_free()
            continue
        item.carried_by = null
        item.flying = false
        item.flight_velocity = Vector2.ZERO
        item.scorched = false
        item.consumed = false
        item.visible = true
        item.last_thrower_index = 0
        item._impact_spent = false
        item._reset_resting()
        item.global_position = _initial_throwable_positions[item.name]
    _held_throwables.clear()
    _portal_cooldown.clear()
    _release_hose()
    _bird_time = 0.0
    _bird_drop_timer = bird_drop_interval
    apples_dropped = 0
    _restore_original_grid()
    _fence_burn_elapsed.clear()
    for idx in 8:
        _fence_burn_elapsed[idx] = 0.0
    _destroyed_by_player = {1: 0, 2: 0}
    _fractional_damage_by_player = {1: 0.0, 2: 0.0}
    _show_status("GARDEN READY • E / SHIFT: INTERACT")


func _show_status(message: String) -> void:
    last_action = message
    var status := arena.get_node_or_null("HUD/Status") as Label
    if status != null:
        status.text = message


func _draw() -> void:
    if _hose_owner == null:
        return
    # Debug spray particles only. Art Team has not supplied a standalone
    # hose jet texture; the nozzle itself is painted into garden.piskel.
    var at := _hose_origin()
    var face := float(_hose_owner.facing)
    for i in range(14):
        var point := at + Vector2(face * float(13 * i), sin(_bird_time * 15.0 + float(i)) * 5.0)
        draw_rect(Rect2(point, Vector2(5.0, 3.0)), Color("#7fcddd"))
