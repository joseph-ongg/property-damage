## Shared standalone pause scene for Living Room and Garden.
## Existing tests still use is_paused, Backdrop and set_paused.
extends CanvasLayer

const U = preload("res://gameplay/presentation/stylekit.gd")
const LOBBY := "res://gameplay/MapSelection/map_select.tscn"
const TITLE := "res://gameplay/presentation/main_menu.tscn"

var is_paused: bool = false
var pause_root: Control
var help_panel: Control
var pause_panel: Control


func _ready() -> void:
    layer = 95
    process_mode = Node.PROCESS_MODE_ALWAYS
    var backdrop := get_node_or_null("Backdrop") as ColorRect
    if backdrop == null:
        backdrop = ColorRect.new()
        backdrop.name = "Backdrop"
        backdrop.color = Color(0.07, 0.09, 0.18, 0.9)
        backdrop.position = Vector2.ZERO
        backdrop.size = Vector2(960, 540)
        add_child(backdrop)
    for child in backdrop.get_children():
        # Existing prototype PauseOverlay visuals are preserved but hidden;
        # the new shared panel replaces them in both real battle maps.
        child.hide()
    backdrop.visible = false
    pause_root = backdrop
    _make_panel()
    _make_help()


func _make_panel() -> void:
    pause_panel = Control.new()
    pause_panel.name = "PauseMenu"
    pause_root.add_child(pause_panel)
    U.card(pause_panel, Vector2(237, 68), Vector2(486, 407), U.GOLD, 0.98)
    U.text(pause_panel, "DUEL PAUSED", Vector2(267, 85), Vector2(424, 52),
        35, U.GOLD, true)
    var resume := U.button(pause_panel, "RESUME  /  ESC", Vector2(305, 153),
        Vector2(350, 43), U.TEAL)
    resume.pressed.connect(func() -> void: set_paused(false))
    var help := U.button(pause_panel, "CONTROLS & RULES", Vector2(305, 205),
        Vector2(350, 41), U.LAVENDER)
    help.pressed.connect(func() -> void: _show_help(true))
    U.text(pause_panel, "LOCAL DUEL  ·  P1: WASD  ·  P2: ARROWS",
        Vector2(299, 275), Vector2(356, 37), 15, U.MUTED, true)
    var rematch := U.button(pause_panel, "RESTART MATCH", Vector2(305, 356),
        Vector2(167, 41), U.PINK)
    rematch.pressed.connect(_restart)
    var lobby := U.button(pause_panel, "BACK TO LOBBY", Vector2(482, 356),
        Vector2(173, 41), U.GOLD)
    lobby.pressed.connect(func() -> void: _change_to(LOBBY))
    var title := U.button(pause_panel, "RETURN TO TITLE", Vector2(307, 415),
        Vector2(346, 39), U.LAVENDER)
    title.pressed.connect(func() -> void: _change_to(TITLE))
    resume.grab_focus()


func _make_help() -> void:
    help_panel = Control.new()
    help_panel.name = "PauseHelp"
    help_panel.visible = false
    pause_root.add_child(help_panel)
    U.card(help_panel, Vector2(206, 73), Vector2(548, 387), U.LAVENDER)
    U.text(help_panel, "HOW TO DUEL", Vector2(277, 92),
        Vector2(404, 51), 33, U.GOLD, true)
    U.text(help_panel, "P1 / MINT", Vector2(245, 148),
        Vector2(190, 28), 20, U.TEAL, true)
    U.text(help_panel, "P2 / CORAL", Vector2(516, 148),
        Vector2(190, 28), 20, U.PINK, true)
    U.text(help_panel, "A / D   MOVE\nW   JUMP\nG   ATTACK\nF   SPARK\nC   PICK / THROW\nE   USE",
        Vector2(255, 190), Vector2(195, 197), 18, U.WHITE)
    U.text(help_panel, "ARROWS   MOVE / JUMP\n.   ATTACK\nENTER   SPARK\n,   PICK / THROW\nSHIFT   USE",
        Vector2(518, 190), Vector2(201, 177), 18, U.WHITE)
    var back := U.button(help_panel, "BACK TO PAUSE", Vector2(345, 390),
        Vector2(270, 47), U.TEAL)
    back.pressed.connect(func() -> void: _show_help(false))


func _show_help(show: bool) -> void:
    pause_panel.visible = not show
    help_panel.visible = show


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
    if key in [KEY_P, KEY_ESCAPE]:
        if help_panel.visible:
            _show_help(false)
        else:
            set_paused(not is_paused)
        get_viewport().set_input_as_handled()
    elif is_paused and key == KEY_R:
        get_viewport().set_input_as_handled()
        _restart()


func set_paused(paused: bool) -> void:
    is_paused = paused
    pause_root.visible = paused
    _show_help(false)
    get_tree().paused = paused


func _restart() -> void:
    set_paused(false)
    # Reset current scene for a completely fresh match and full item state.
    get_tree().reload_current_scene()


func _change_to(path: String) -> void:
    set_paused(false)
    get_tree().change_scene_to_file(path)


func _exit_tree() -> void:
    if is_paused:
        get_tree().paused = false
