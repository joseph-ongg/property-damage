## Reusable local two-player best-of-three flow; no new duplicate HP store.
class_name GameplayMatchManager
extends CanvasLayer

signal round_finished(winner_index: int, scores: Array[int])
signal match_finished(winner_index: int)

const RULES: GameplayTuning = preload("res://gameplay/tuning/gameplay_balance.tres")
const MENU_SCENE := "res://gameplay/MapSelection/map_select.tscn"

@export_node_path("GameplayPlayer") var player1_path: NodePath = NodePath("../Player1")
@export_node_path("GameplayPlayer") var player2_path: NodePath = NodePath("../Player2")
@export_node_path("Node") var projectile_container_path: NodePath = NodePath("../Projectiles")

var player1: GameplayPlayer
var player2: GameplayPlayer
var round_number: int = 1
var p1_wins: int = 0
var p2_wins: int = 0
var round_over: bool = false
var match_over: bool = false

var score_label: Label
var panel: PanelContainer
var headline: Label
var detail: Label
var continue_button: Button

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
    _create_hud()
    _refresh_score()
    call_deferred("_capture_round_state")


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


func _create_hud() -> void:
    score_label = Label.new()
    score_label.position = Vector2(340, 12)
    score_label.size = Vector2(290, 28)
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    score_label.add_theme_color_override("font_color", Color("#f4e6c6"))
    score_label.add_theme_font_size_override("font_size", 15)
    add_child(score_label)

    panel = PanelContainer.new()
    panel.position = Vector2(274, 140)
    panel.custom_minimum_size = Vector2(410, 260)
    panel.visible = false
    add_child(panel)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    panel.add_child(stack)

    headline = Label.new()
    headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    headline.add_theme_font_size_override("font_size", 29)
    stack.add_child(headline)
    detail = Label.new()
    detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    detail.add_theme_font_size_override("font_size", 17)
    stack.add_child(detail)
    continue_button = Button.new()
    continue_button.custom_minimum_size = Vector2(310, 48)
    continue_button.pressed.connect(continue_after_round)
    stack.add_child(continue_button)
    var rematch := Button.new()
    rematch.text = "New Match"
    rematch.custom_minimum_size = Vector2(310, 42)
    rematch.pressed.connect(new_match)
    stack.add_child(rematch)
    var maps := Button.new()
    maps.text = "Character / Map Select"
    maps.custom_minimum_size = Vector2(310, 42)
    maps.pressed.connect(back_to_menu)
    stack.add_child(maps)


func _refresh_score() -> void:
    if score_label == null:
        return
    score_label.text = "P1  %d  :  %d  P2    |    ROUND %d" % [p1_wins, p2_wins, round_number]


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
    player1.set_physics_process(false)
    player2.set_physics_process(false)
    var projectiles := get_node_or_null(projectile_container_path)
    if projectiles != null:
        for projectile in projectiles.get_children():
            projectile.queue_free()
    _refresh_score()
    headline.text = "P%d WINS %s" % [winner_index, "THE MATCH!" if match_over else "THE ROUND!"]
    detail.text = "Best of %d    |    P1: %d    P2: %d" % [2 * RULES.rounds_to_win - 1, p1_wins, p2_wins]
    continue_button.visible = not match_over
    continue_button.text = "Next Round (R)"
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
    round_number = 1
    match_over = false
    _reset_round()


func _reset_round() -> void:
    _reset_level_state()
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
    panel.visible = false
    _refresh_score()


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
