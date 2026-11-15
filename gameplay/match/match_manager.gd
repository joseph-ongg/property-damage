## Reusable local two-player best-of-three flow; no new duplicate HP store.
class_name GameplayMatchManager
extends CanvasLayer

signal round_finished(winner_index: int, scores: Array[int])
signal match_finished(winner_index: int)

const RULES: GameplayTuning = preload("res://gameplay/tuning/gameplay_balance.tres")
const U = preload("res://gameplay/presentation/stylekit.gd")
const Selection = preload("res://gameplay/characters/character_selection_state.gd")
const TITLE := "res://gameplay/presentation/main_menu.tscn"
const MENU_SCENE := "res://gameplay/MapSelection/map_select.tscn"

@export_node_path("GameplayPlayer") var player1_path: NodePath = NodePath("../Player1")
@export_node_path("GameplayPlayer") var player2_path: NodePath = NodePath("../Player2")
@export_node_path("Node") var projectile_container_path: NodePath = NodePath("../Projectiles")

var player1: GameplayPlayer
var player2: GameplayPlayer
var round_number: int = 1
var round_seconds_left: float = 120.0
var _last_display_seconds: int = -1
var p1_wins: int = 0
var p2_wins: int = 0
var round_over: bool = false
var match_over: bool = false

var score_label: Label
var panel: PanelContainer
var headline: Label
var detail: Label
var continue_button: Button
var new_match_button: Button
var result_backdrop: TextureRect
var result_portrait: TextureRect
var result_stats: Label
var p1_bar: ProgressBar
var p2_bar: ProgressBar
var p1_health_text: Label
var p2_health_text: Label
var p1_kind_text: Label
var p2_kind_text: Label
var countdown_label: Label
var countdown_remaining: float = 0.0
var _previous_count: int = -1
var _hud_refresh_age: float = 0.0
var damage_taken: Array[int] = [0, 0]
var destroyed_total: Array[int] = [0, 0]
var _show_countdown: bool = false

# Capture the original state after the parent has seeded all materials.
var _initial_items: Dictionary = {}
var _initial_materials: Array = []


func _ready() -> void:
    layer = 60
    process_mode = Node.PROCESS_MODE_ALWAYS
    player1 = get_node(player1_path) as GameplayPlayer
    player2 = get_node(player2_path) as GameplayPlayer
    if player1 == null or player2 == null:
        push_error("Match Manager requires two real GameplayPlayer prefabs")
        return
    player1.health.died.connect(_on_player_died.bind(1))
    player2.health.died.connect(_on_player_died.bind(2))
    player1.health.changed.connect(_refresh_health.unbind(2))
    player2.health.changed.connect(_refresh_health.unbind(2))
    player1.health.damaged.connect(_on_hurt.bind(1))
    player2.health.damaged.connect(_on_hurt.bind(2))
    round_seconds_left = RULES.round_seconds
    _create_hud()
    _refresh_score()
    _refresh_health()
    call_deferred("_capture_round_state")
    _show_countdown = bool(Selection.has_selection and player1.use_menu_character_selection)
    if _show_countdown:
        _hide_old_room_header()
        _start_countdown()


func _hide_old_room_header() -> void:
    # Only the real menu-driven match uses the full presentation HUD.
    # Direct prototype/test scenes retain their old HUD node contract.
    var arena := get_parent()
    if arena.has_node("HUD"):
        for section in ["TopBar", "TopBarAccent", "Title", "Subtitle",
                "SystemHint", "StatusBack", "StatusAccent", "StatusHeading", "SparkStatus"]:
            var node := arena.get_node_or_null("HUD/" + section) as CanvasItem
            if node != null:
                node.hide()


func _on_hurt(amount: int, player_index: int) -> void:
    damage_taken[player_index - 1] += amount


func _start_countdown() -> void:
    countdown_remaining = 2.4
    _previous_count = -1
    countdown_label.visible = true
    player1.input_locked = true
    player2.input_locked = true


func _process(delta: float) -> void:
    if not get_tree().paused and not round_over:
        _hud_refresh_age += delta
        if _hud_refresh_age >= 0.2:
            _hud_refresh_age = 0.0
            _refresh_health()
    if countdown_remaining <= 0.0 and not get_tree().paused and not round_over:
        round_seconds_left = maxf(0.0, round_seconds_left - delta)
        var shown := ceili(round_seconds_left)
        if shown != _last_display_seconds:
            _last_display_seconds = shown
            _refresh_score()
        if round_seconds_left <= 0.0:
            _on_timeout()
        return
    if countdown_remaining <= 0.0 or get_tree().paused or round_over:
        return
    countdown_remaining -= delta
    var count := clampi(ceili(countdown_remaining / 0.8), 0, 3)
    countdown_label.text = "DUEL!" if count == 0 else str(count)
    if count != _previous_count:
        _previous_count = count
    if countdown_remaining <= 0.0:
        player1.input_locked = false
        player2.input_locked = false
        var tween := create_tween()
        tween.tween_interval(0.55)
        tween.tween_callback(func() -> void: countdown_label.hide())


func _capture_round_state() -> void:
    _initial_items.clear()
    for candidate in get_tree().get_nodes_in_group("interactable_items"):
        var item := candidate as GameplayInteractableItem
        if item == null or not get_parent().is_ancestor_of(item):
            continue
        var snapshot := {
            "position": item.global_position,
            "max_hp": item.max_hp,
        }
        if item is GameplayWorldItem:
            var world := item as GameplayWorldItem
            snapshot["opened"] = world.opened
            snapshot["powered"] = world.powered
            snapshot["plugged"] = world.plugged
            snapshot["contents"] = world.contents
            snapshot["warm"] = world.warm
            snapshot["removed"] = world.removed_from_fridge
        _initial_items[item] = snapshot
    _initial_materials.clear()
    var grid := get_parent().get_node_or_null("MaterialGrid") as MaterialGrid
    if grid == null:
        return
    for x in grid.width:
        var column: Array[int] = []
        for y in grid.height:
            column.append(int(grid.get_cell_material(x, y)))
        _initial_materials.append(column)


func _reset_level_state() -> void:
    for item: GameplayInteractableItem in _initial_items.keys():
        if not is_instance_valid(item):
            continue
        var old: Dictionary = _initial_items[item]
        item.global_position = old["position"]
        item.hp = float(old["max_hp"])
        item.destroyed_item = false
        item.burned_to_ash = false
        item.burning = false
        item._burn_age = 0.0
        item._burn_damage_age = 0.0
        item._fire_contact_latched = false
        item._fire_damage_call = false
        if item.has_method("reset_visual_effects"):
            item.call("reset_visual_effects")
        if item is GameplayBurnableProp:
            var prop := item as GameplayBurnableProp
            prop.carried_by = null
            prop.flying = false
            prop.flight_velocity = Vector2.ZERO
            prop.thrower_index = -1
            prop._hit_players.clear()
            prop._reset_resting()
            prop.scorched = false
            prop.flash_left = 0.0
        if item is GameplayWorldItem:
            var world := item as GameplayWorldItem
            world.opened = bool(old["opened"])
            world.powered = bool(old["powered"])
            world.plugged = bool(old["plugged"])
            world.contents = int(old["contents"])
            world.warm = bool(old["warm"])
            world.removed_from_fridge = bool(old["removed"])
            world._shards_active = false
            world._shard_hits.clear()
            world._trash_cooldowns.clear()
            world._prior_trash_feet.clear()
        if item is GameplayAppliance:
            var appliance := item as GameplayAppliance
            appliance.switched_on = false
            appliance.charred = false
        item.queue_redraw()
    var arena := get_parent()
    if "held_items" in arena:
        arena.held_items.clear()
    var grid := arena.get_node_or_null("MaterialGrid") as MaterialGrid
    if grid != null and _initial_materials.size() == grid.width:
        grid.wind_direction = Vector2.ZERO
        grid.wind_strength = 0.0
        for x in grid.width:
            for y in grid.height:
                var material := int(_initial_materials[x][y])
                if grid.get_cell_material(x, y) != material or grid.is_burning(x, y):
                    grid.set_cell_material(x, y, material)


func _make_health_bar(at: Vector2, accent: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.position = at
    bar.size = Vector2(215, 15)
    bar.custom_minimum_size = Vector2(215, 15)
    bar.show_percentage = false
    bar.min_value = 0
    bar.max_value = 100
    var empty := StyleBoxFlat.new()
    empty.bg_color = Color("#151a31")
    empty.border_color = Color("#9295ba")
    empty.border_width_left = 1
    empty.border_width_right = 1
    empty.border_width_top = 1
    empty.border_width_bottom = 1
    var full := StyleBoxFlat.new()
    full.bg_color = accent
    full.border_color = accent.lightened(0.25)
    full.border_width_left = 1
    full.border_width_right = 1
    full.border_width_top = 1
    full.border_width_bottom = 1
    bar.add_theme_stylebox_override("background", empty)
    bar.add_theme_stylebox_override("fill", full)
    add_child(bar)
    return bar


func _create_hud() -> void:
    U.card(self, Vector2(9, 8), Vector2(315, 64), U.TEAL, 0.96)
    U.card(self, Vector2(636, 8), Vector2(315, 64), U.PINK, 0.96)
    U.card(self, Vector2(342, 8), Vector2(276, 64), U.GOLD, 0.96)
    U.portrait(self, player1.character_kind, Vector2(13, 12), Vector2(56, 55))
    U.portrait(self, player2.character_kind, Vector2(892, 12), Vector2(56, 55))
    p1_kind_text = U.text(self, "", Vector2(80, 10), Vector2(230, 25), 15, U.TEAL)
    p2_kind_text = U.text(self, "", Vector2(648, 10), Vector2(232, 25), 15, U.PINK)
    p1_bar = _make_health_bar(Vector2(80, 35), U.TEAL)
    p2_bar = _make_health_bar(Vector2(649, 35), U.PINK)
    p1_health_text = U.text(self, "", Vector2(80, 54), Vector2(232, 15), 11, U.WHITE)
    p2_health_text = U.text(self, "", Vector2(648, 54), Vector2(234, 15), 11, U.WHITE)
    score_label = U.text(self, "", Vector2(347, 18), Vector2(269, 48), 21, U.GOLD, true)
    countdown_label = U.text(self, "", Vector2(342, 173), Vector2(276, 125), 64, U.GOLD, true)
    countdown_label.visible = false

    result_backdrop = TextureRect.new()
    result_backdrop.position = Vector2(195, 75)
    result_backdrop.size = Vector2(570, 404)
    result_backdrop.texture = load(U.DIR + "result_backdrop.png")
    result_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    result_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
    result_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(result_backdrop)
    result_backdrop.visible = false
    panel = U.card(self, Vector2(223, 92), Vector2(514, 374), U.GOLD, 0.97)
    panel.name = "MatchResult"
    panel.visible = false
    var contents := Control.new()
    contents.custom_minimum_size = Vector2(510, 370)
    panel.add_child(contents)
    headline = U.text(contents, "ROUND COMPLETE", Vector2(21, 17),
        Vector2(460, 39), 27, U.GOLD, true)
    detail = U.text(contents, "", Vector2(40, 57),
        Vector2(420, 28), 16, U.WHITE, true)
    result_portrait = U.portrait(contents, "mage", Vector2(196, 86), Vector2(110, 134))
    result_stats = U.text(contents, "", Vector2(35, 215),
        Vector2(440, 26), 14, U.TEAL, true)
    continue_button = U.button(contents, "NEXT ROUND", Vector2(21, 255),
        Vector2(228, 41), U.TEAL)
    continue_button.pressed.connect(continue_after_round)
    new_match_button = U.button(contents, "REMATCH", Vector2(259, 255),
        Vector2(228, 41), U.PINK)
    new_match_button.pressed.connect(new_match)
    var maps := U.button(contents, "CHANGE FIGHTERS / MAP", Vector2(21, 303),
        Vector2(228, 40), U.LAVENDER)
    maps.pressed.connect(back_to_menu)
    var title := U.button(contents, "MAIN MENU", Vector2(259, 303),
        Vector2(228, 40), U.GOLD)
    title.pressed.connect(func() -> void: _go_to_title())


func _refresh_health() -> void:
    if p1_bar == null:
        return
    p1_bar.max_value = player1.health.max_hp
    p1_bar.value = player1.health.hp
    p2_bar.max_value = player2.health.max_hp
    p2_bar.value = player2.health.hp
    p1_kind_text.text = "P1 / " + player1.character_kind.to_upper()
    p2_kind_text.text = "P2 / " + player2.character_kind.to_upper()
    p1_health_text.text = "HP %d / %d    ATK %.1f" % [player1.health.hp, player1.health.max_hp, player1.attack_damage]
    p2_health_text.text = "HP %d / %d    ATK %.1f" % [player2.health.hp, player2.health.max_hp, player2.attack_damage]


func _refresh_score() -> void:
    if score_label == null:
        return
    score_label.text = "%d  :  %d    %02d s\nROUND %d" % [
        p1_wins, p2_wins, ceili(round_seconds_left), round_number]


func _go_to_title() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file(TITLE)


func _on_timeout() -> void:
    # Compare remaining health percentages so low-HP, high-speed fighters are
    # not inherently disadvantaged by their character max HP.
    var first := float(player1.health.hp) / maxf(1.0, float(player1.health.max_hp))
    var second := float(player2.health.hp) / maxf(1.0, float(player2.health.max_hp))
    if absf(first - second) < 0.0001:
        _declare_draw()
        return
    _on_player_died(2 if first > second else 1)


func _declare_draw() -> void:
    if round_over:
        return
    round_over = true
    _set_environment_running(false)
    player1.set_physics_process(false)
    player2.set_physics_process(false)
    var projectiles := get_node_or_null(projectile_container_path)
    if projectiles != null:
        for projectile in projectiles.get_children():
            projectile.queue_free()
    _refresh_score()
    headline.text = "DRAW  /  NO VICTOR"
    detail.text = "TIME EXPIRED  ·  BOTH FIGHTERS ARE EVEN"
    result_portrait.visible = false
    result_stats.text = "A new round will decide the winner."
    continue_button.visible = true
    new_match_button.position = Vector2(259, 255)
    new_match_button.size = Vector2(228, 41)
    result_backdrop.visible = true
    panel.visible = true
    round_finished.emit(0, [p1_wins, p2_wins])


func _set_environment_running(running: bool) -> void:
    # The result screen stays interactive, but fire spread and item damage
    # cannot keep evolving after the game has declared a winner or a draw.
    var arena := get_parent()
    var grid := arena.get_node_or_null("MaterialGrid") as MaterialGrid
    if grid != null:
        var timer := grid.get_node_or_null("TickTimer") as Timer
        if timer != null:
            timer.paused = not running
    for candidate in get_tree().get_nodes_in_group("interactable_items"):
        var item := candidate as GameplayInteractableItem
        if item != null and arena.is_ancestor_of(item):
            item.set_process(running)


func _on_player_died(loser_index: int) -> void:
    if round_over:
        return
    var winner_index := 2 if loser_index == 1 else 1
    round_over = true
    if winner_index == 1:
        p1_wins += 1
    else:
        p2_wins += 1
    match_over = p1_wins >= RULES.rounds_to_win or p2_wins >= RULES.rounds_to_win
    _set_environment_running(false)
    player1.set_physics_process(false)
    player2.set_physics_process(false)
    destroyed_total[0] += player1.destroyed_objects
    destroyed_total[1] += player2.destroyed_objects
    var projectiles := get_node_or_null(projectile_container_path)
    if projectiles != null:
        for projectile in projectiles.get_children():
            projectile.queue_free()
    _refresh_score()
    headline.text = "P%d / %s" % [winner_index, "VICTORY!" if match_over else "ROUND WON"]
    detail.text = "BEST OF %d    •    P1: %d   P2: %d" % [2 * RULES.rounds_to_win - 1, p1_wins, p2_wins]
    result_portrait.visible = true
    result_portrait.texture = load(U.DIR + "portrait_%s.png" %
        (player1.character_kind if winner_index == 1 else player2.character_kind))
    result_stats.text = "HP LOST: %d / %d   •   OBJECTS: %d / %d" % [
        damage_taken[0], damage_taken[1], destroyed_total[0], destroyed_total[1]]
    continue_button.visible = not match_over
    new_match_button.text = "NEW MATCH" if match_over else "RESTART MATCH"
    new_match_button.position = Vector2(21, 255) if match_over else Vector2(259, 255)
    new_match_button.size = Vector2(466, 41) if match_over else Vector2(228, 41)
    result_backdrop.visible = true
    panel.visible = true
    round_finished.emit(winner_index, [p1_wins, p2_wins])
    if match_over:
        match_finished.emit(winner_index)


func continue_after_round() -> void:
    if not round_over or match_over:
        return
    round_number += 1
    _reset_round()


func new_match() -> void:
    p1_wins = 0
    p2_wins = 0
    damage_taken = [0, 0]
    destroyed_total = [0, 0]
    round_number = 1
    match_over = false
    _reset_round()


func _reset_round() -> void:
    _reset_level_state()
    _set_environment_running(true)
    for player: GameplayPlayer in [player1, player2]:
        player.respawn(true)
        player.destroyed_objects = 0
        player.attack_damage = RULES.base_attack_damage
        player.set_physics_process(true)
    var projectiles := get_node_or_null(projectile_container_path)
    if projectiles != null:
        for projectile in projectiles.get_children():
            projectile.queue_free()
    round_over = false
    round_seconds_left = RULES.round_seconds
    _last_display_seconds = -1
    panel.visible = false
    result_backdrop.visible = false
    countdown_label.visible = false
    _refresh_score()
    _refresh_health()
    if _show_countdown:
        _start_countdown()


func back_to_menu() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file(MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
    if not round_over or not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.physical_keycode == KEY_R:
        if match_over:
            new_match()
        else:
            continue_after_round()
        get_viewport().set_input_as_handled()
