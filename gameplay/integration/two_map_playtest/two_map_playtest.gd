## EXPERIMENTAL PLAYTEST ADAPTER — not a change to Angela/Austin/Eva modules.
## Reuses Angela's two-map buttons, PR18 Garden, existing Living Room, Eva's
## Health, and Garden PvP collider. No match win condition is assumed.
extends Node2D

signal scene_started(arena_name: String)
signal round_ended(winner_index: int)
signal playtest_ended(rounds_played: int)

const ADAPTER_SCRIPT: GDScript = preload("res://gameplay/integration/two_map_playtest/angela_map_adapter.gd")
const MAP_SELECT: PackedScene = preload("res://gameplay/LevelSelection/map_select.tscn")
const GARDEN := "res://gameplay/garden/garden_level.tscn"
const LIVING := "res://gameplay/msd/gameplay_msd.tscn"
const KINDS := ["mage", "ninja", "werewolf"]
const PRETTY := ["Wizard", "Ninja", "Werewolf"]

var selected_kinds: Array[String] = ["mage", "mage"]
var selected_map: String = ""
var arena: Node2D
var scores: Dictionary = {1: 0, 2: 0}
var round_number := 0
var round_over := false
var screen_mode := "character"

@onready var arena_host: Node2D = $ArenaHost
@onready var screen: Control = $ScreenLayer/Screen

func _ready() -> void:
    get_window().content_scale_size = Vector2i(960, 540)
    get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    _show_characters()

func _clear_screen() -> void:
    for child in screen.get_children():
        screen.remove_child(child)
        child.queue_free()

func _button(label_text: String, parent: Node, method: Callable, width: float = 400.0) -> Button:
    var b := Button.new()
    b.text = label_text
    b.custom_minimum_size = Vector2(width, 45)
    b.add_theme_font_size_override("font_size", 19)
    parent.add_child(b)
    b.pressed.connect(method)
    return b

func _label(txt: String, parent: Node, size: int = 18) -> Label:
    var l := Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size", size)
    parent.add_child(l)
    return l

func _panel_stack() -> VBoxContainer:
    var background := ColorRect.new()
    background.name = "MenuBackground"
    background.color = Color(0.07, 0.09, 0.15, 0.98)
    background.size = Vector2(960, 540)
    background.mouse_filter = Control.MOUSE_FILTER_STOP
    screen.add_child(background)
    var v := VBoxContainer.new()
    v.name = "MenuStack"
    v.position = Vector2(205, 50)
    v.custom_minimum_size = Vector2(550, 430)
    screen.add_child(v)
    v.add_theme_constant_override("separation", 17)
    return v

func _show_characters() -> void:
    _release_arena()
    _clear_screen()
    screen_mode = "character"
    var box := _panel_stack()
    _label("PROPERTY DAMAGE", box, 37)
    _label("EXPERIMENTAL | NOT DESIGN APPROVED | match rules pending", box, 17)
    _label("P1 character", box, 17)
    var p1 := OptionButton.new()
    p1.name = "P1Choice"
    box.add_child(p1)
    _label("P2 character", box, 17)
    var p2 := OptionButton.new()
    p2.name = "P2Choice"
    box.add_child(p2)
    for index in range(KINDS.size()):
        p1.add_item(PRETTY[index], index)
        p2.add_item(PRETTY[index], index)
    p1.select(KINDS.find(selected_kinds[0]))
    p2.select(KINDS.find(selected_kinds[1]))
    _button("Choose one of the two approved maps", box, func() -> void:
        selected_kinds = [KINDS[p1.selected], KINDS[p2.selected]]
        _show_map_selection()
    )
    _label("Design specs: only Living Room / Bedroom + Garden", box, 14)

func _show_map_selection() -> void:
    _clear_screen()
    screen_mode = "map"
    var menu := MAP_SELECT.instantiate() as Control
    menu.name = "AngelasMapSelect"
    menu.set_script(ADAPTER_SCRIPT)
    screen.add_child(menu)
    menu.playtest_map_selected.connect(_on_map_selected)
    # Parent's Control anchors are preserved; no third-map button is added.
    var banner := Label.new()
    banner.name = "MapBanner"
    banner.text = "PROPERTY DAMAGE | map selector from Angela | two approved arenas"
    banner.position = Vector2(70, 20)
    banner.add_theme_font_size_override("font_size", 19)
    screen.add_child(banner)
    var back := Button.new()
    back.name = "BackToCharacters"
    back.text = "Back to character choices"
    back.position = Vector2(55, 468)
    back.size = Vector2(260, 46)
    screen.add_child(back)
    back.pressed.connect(_show_characters)

func _on_map_selected(path: String) -> void:
    if path != GARDEN and path != "res://gameplay/playtest_main.tscn":
        push_error("Blocked unexpected map selection " + path)
        return
    selected_map = GARDEN if path == GARDEN else LIVING
    scores = {1: 0, 2: 0}
    round_number = 0
    _start_round()

func _release_arena() -> void:
    if is_instance_valid(arena):
        arena_host.remove_child(arena)
        arena.queue_free()
        arena = null

func _start_round() -> void:
    _release_arena()
    _clear_screen()
    round_number += 1
    round_over = false
    screen_mode = "fight"
    arena = (load(selected_map) as PackedScene).instantiate() as Node2D
    arena_host.add_child(arena)
    if selected_map == LIVING:
        # Temporary hit adapter only: do NOT edit Austin's projectile or room
        # script. Existing room visual/VFX and owner features remain intact.
        var empty_fences := Node2D.new()
        empty_fences.name = "Fences"
        arena.add_child(empty_fences)
        var legacy := Callable(arena, "_on_magic_attack")
        for idx in [1, 2]:
            var p := arena.get_node("Player%d" % idx) as GameplayPlayer
            if p.magic_attacked.is_connected(legacy):
                p.magic_attacked.disconnect(legacy)
            p.magic_attacked.connect(_living_room_attack)
    for idx in [1, 2]:
        var player := arena.get_node("Player%d" % idx) as GameplayPlayer
        player.set_character_kind(selected_kinds[idx - 1])
        player.health_component.died.connect(_on_fighter_died.bind(idx))
    _show_fight_hud()
    scene_started.emit("Garden" if selected_map == GARDEN else "Living Room")

func _living_room_attack(_idx: int, player: GameplayPlayer) -> void:
    if round_over or not player.health_component.is_alive():
        return
    # Reuse already tested design-aligned 10-damage PvP projectile.
    # The room's native original bolt has been disconnected only here.
    var bolt := GameplayGardenMagicBolt.new()
    arena.get_node("Projectiles").add_child(bolt)
    bolt.initialize(player)

func _on_fighter_died(loser_index: int) -> void:
    if round_over:
        return
    round_over = true
    var winner := 3 - loser_index
    scores[winner] += 1
    for idx in [1, 2]:
        var p := arena.get_node("Player%d" % idx) as GameplayPlayer
        p.velocity = Vector2.ZERO
        p.set_physics_process(false)
    var loser := arena.get_node("Player%d" % loser_index) as GameplayPlayer
    loser.sprite.rotation = 0.68 * float(loser.facing)
    loser.sprite.modulate = Color(0.70, 0.70, 0.70, 0.8)
    loser.get_node("NameTag").text = "KO"
    for bullet in arena.get_node("Projectiles").get_children():
        bullet.set_physics_process(false)
        bullet.queue_free()
    round_ended.emit(winner)
    _show_result(winner)

func _show_fight_hud() -> void:
    var row := HBoxContainer.new()
    row.name = "FightHUD"
    row.position = Vector2(22, 8)
    screen.add_child(row)
    var line := _label("", row, 15)
    line.name = "FightStatus"
    var quit_button := Button.new()
    quit_button.name = "QuitToMaps"
    quit_button.text = "Return to maps"
    quit_button.position = Vector2(770, 4)
    quit_button.size = Vector2(167, 34)
    quit_button.focus_mode = Control.FOCUS_NONE
    screen.add_child(quit_button)
    quit_button.pressed.connect(_back_to_maps)
    var instruction := Label.new()
    instruction.text = "P1: A/D + G | P2: arrows + period | 10 HP base"
    instruction.position = Vector2(22, 515)
    instruction.add_theme_font_size_override("font_size", 13)
    screen.add_child(instruction)
    _refresh_health()

func _refresh_health() -> void:
    if screen_mode != "fight" or not is_instance_valid(arena):
        return
    var label := screen.get_node_or_null("FightHUD/FightStatus") as Label
    if label == null:
        return
    var p1 := arena.get_node("Player1") as GameplayPlayer
    var p2 := arena.get_node("Player2") as GameplayPlayer
    label.text = "Property Damage | R%d | P1 %d/%d HP (%d win)  vs  P2 %d/%d HP (%d win)" % [
        round_number,
        p1.health_component.hp, p1.health_component.max_hp, scores[1],
        p2.health_component.hp, p2.health_component.max_hp, scores[2]]

func _process(_delta: float) -> void:
    _refresh_health()

func _show_result(winner: int) -> void:
    # This is a round result only. There is NO automatic match winner.
    var shade := ColorRect.new()
    shade.name = "RoundShade"
    shade.color = Color(0.02, 0.03, 0.08, 0.88)
    shade.position = Vector2(215, 150)
    shade.size = Vector2(530, 320)
    screen.add_child(shade)
    var v := VBoxContainer.new()
    v.name = "ResultPanel"
    v.position = Vector2(252, 182)
    v.custom_minimum_size = Vector2(455, 275)
    v.add_theme_constant_override("separation", 14)
    screen.add_child(v)
    _label("P%d WINS THIS ROUND" % winner, v, 27)
    _label("Round wins: P1 %d - P2 %d (not match scoring)" % [scores[1], scores[2]], v, 15)
    _button("Next round", v, _start_round)
    _button("Finish playtest (no match winner)", v, _finish_playtest)
    _button("Back to map selection", v, _back_to_maps)

## Explicit user-driven end of this test session; never decides a match winner.
func _finish_playtest() -> void:
    var total_rounds := round_number
    _release_arena()
    _clear_screen()
    screen_mode = "summary"
    var v := _panel_stack()
    _label("PLAYTEST SESSION COMPLETE", v, 27)
    _label("EXPERIMENTAL / NOT DESIGN APPROVED", v, 17)
    _label("No official match winner: waiting for Design specs", v, 17)
    _label("Rounds: %d | P1 round wins: %d | P2 round wins: %d" % [
        total_rounds, scores[1], scores[2]], v, 17)
    _button("Restart playtest", v, _rematch)
    _button("Back to map selection", v, _back_to_maps)
    _button("Back to character selection", v, _show_characters)
    playtest_ended.emit(total_rounds)


func _rematch() -> void:
    scores = {1: 0, 2: 0}
    round_number = 0
    _start_round()

func _back_to_maps() -> void:
    _release_arena()
    scores = {1: 0, 2: 0}
    round_number = 0
    _show_map_selection()
