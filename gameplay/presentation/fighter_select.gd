## Local-only two-fighter registration BEFORE Angela's untouched map screen.
## Angela's 55fe753 map-select script, map routes and buttons are not edited.
extends Control

const U = preload("res://gameplay/presentation/stylekit.gd")
const Selection = preload("res://gameplay/characters/character_selection_state.gd")
const MAPS := "res://gameplay/MapSelection/map_select.tscn"
const TITLE := "res://gameplay/presentation/main_menu.tscn"
const KINDS: Array[String] = ["mage", "ninja", "werewolf"]
const STATS := {
    "mage": "120 HP  •  FIRE MAGIC  •  BALANCED",
    "ninja": "100 HP  •  SHURIKEN  •  FAST",
    "werewolf": "160 HP  •  CLAWS  •  DURABLE",
}

var player_kinds: Array[int] = [0, 1]
var player_ready: Array[bool] = [false, false]
var portraits: Array[TextureRect] = []
var name_labels: Array[Label] = []
var stats_labels: Array[Label] = []
var ready_buttons: Array[Button] = []
var start_button: Button
var status_label: Label


func _ready() -> void:
    U.background(self, "lobby_backdrop.png")
    U.card(self, Vector2(36, 20), Vector2(888, 96), U.GOLD, 0.96)
    U.text(self, "FIGHTER REGISTRATION", Vector2(64, 34),
        Vector2(832, 46), 34, U.GOLD, true)
    U.text(self, "BOTH PLAYERS MUST LOCK IN BEFORE CHOOSING AN ARENA",
        Vector2(104, 79), Vector2(753, 30), 14, U.WHITE, true)
    for i in 2:
        _make_fighter(i)
    status_label = U.text(self, "", Vector2(196, 466),
        Vector2(568, 24), 15, U.GOLD, true)
    start_button = U.button(self, "CHOOSE ARENA", Vector2(358, 496),
        Vector2(244, 37), U.GOLD)
    start_button.pressed.connect(_continue_to_maps)
    start_button.disabled = true
    _refresh()
    start_button.focus_mode = Control.FOCUS_NONE


func _make_fighter(player: int) -> void:
    var xpos := 40 + player * 457
    var accent: Color = U.TEAL if player == 0 else U.PINK
    U.card(self, Vector2(xpos, 133), Vector2(425, 331), accent, 0.97)
    U.text(self, "PLAYER %d" % (player + 1), Vector2(xpos + 15, 141),
        Vector2(391, 35), 23, accent, true)
    var portrait := U.portrait(self, KINDS[player_kinds[player]],
        Vector2(xpos + 128, 181), Vector2(168, 155))
    portraits.append(portrait)
    name_labels.append(U.text(self, "", Vector2(xpos + 33, 335),
        Vector2(359, 31), 21, U.WHITE, true))
    stats_labels.append(U.text(self, "", Vector2(xpos + 15, 367),
        Vector2(391, 28), 13, U.MUTED, true))
    var left := U.button(self, "◀", Vector2(xpos + 38, 261),
        Vector2(55, 44), accent)
    left.pressed.connect(_cycle.bind(player, -1))
    var right := U.button(self, "▶", Vector2(xpos + 332, 261),
        Vector2(55, 44), accent)
    right.pressed.connect(_cycle.bind(player, 1))
    var ready := U.button(self, "READY  /  CONFIRM", Vector2(xpos + 85, 412),
        Vector2(256, 41), accent)
    ready.toggle_mode = true
    ready.toggled.connect(_set_ready.bind(player))
    ready_buttons.append(ready)


func _refresh() -> void:
    for i in 2:
        var kind := KINDS[player_kinds[i]]
        portraits[i].texture = load(U.DIR + "portrait_%s.png" % kind)
        name_labels[i].text = kind.to_upper()
        stats_labels[i].text = STATS[kind]
        ready_buttons[i].text = "LOCKED IN" if player_ready[i] else "READY  /  CONFIRM"
    start_button.disabled = not (player_ready[0] and player_ready[1])
    status_label.text = ("BOTH READY  •  PRESS ENTER TO SELECT MAP"
        if not start_button.disabled else
        "P1: A / D + G   •   P2: ← / → + .   •   ENTER")


func _cycle(player: int, direction: int) -> void:
    if player_ready[player]:
        return
    player_kinds[player] = posmod(player_kinds[player] + direction, KINDS.size())
    _refresh()


func _set_ready(on: bool, player: int) -> void:
    player_ready[player] = on
    _refresh()


func _continue_to_maps() -> void:
    if start_button.disabled:
        return
    if Selection.choose(KINDS[player_kinds[0]], KINDS[player_kinds[1]]):
        get_tree().change_scene_to_file(MAPS)


func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
    match key:
        KEY_ESCAPE:
            get_tree().change_scene_to_file(TITLE)
        KEY_A: _cycle(0, -1)
        KEY_D: _cycle(0, 1)
        KEY_LEFT: _cycle(1, -1)
        KEY_RIGHT: _cycle(1, 1)
        KEY_G: ready_buttons[0].button_pressed = not ready_buttons[0].button_pressed
        KEY_PERIOD: ready_buttons[1].button_pressed = not ready_buttons[1].button_pressed
        KEY_ENTER:
            _continue_to_maps()
        _: return
    get_viewport().set_input_as_handled()
