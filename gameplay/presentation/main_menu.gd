## Original pixel-fantasy title scene. F5 now enters a standalone front door.
extends Control

const U = preload("res://gameplay/presentation/stylekit.gd")
const LOBBY := "res://gameplay/MapSelection/map_select.tscn"
const HELP := "res://gameplay/presentation/help_screen.tscn"
const SETTINGS := "res://gameplay/presentation/settings_screen.tscn"
const CREDITS := "res://gameplay/presentation/credits_screen.tscn"

var start_button: Button


func _ready() -> void:
    U.background(self, "title_backdrop.png")
    U.text(self, "A R C A N E     A C A D E M Y", Vector2(135, 57),
        Vector2(690, 43), 22, U.GOLD, true)
    U.text(self, "PROPERTY DAMAGE", Vector2(70, 116),
        Vector2(820, 83), 63, U.WHITE, true)
    U.text(self, "REVERIE DUELS  /  LOCAL TWO-PLAYER", Vector2(150, 200),
        Vector2(660, 37), 18, U.TEAL, true)
    U.card(self, Vector2(299, 254), Vector2(363, 208), U.GOLD)
    start_button = U.button(self, "LOCAL VERSUS", Vector2(325, 272),
        Vector2(311, 45), U.TEAL)
    start_button.pressed.connect(_enter_lobby)
    var tutorial := U.button(self, "HOW TO PLAY", Vector2(325, 322),
        Vector2(311, 38), U.LAVENDER)
    tutorial.pressed.connect(func() -> void: get_tree().change_scene_to_file(HELP))
    var options := U.button(self, "SETTINGS", Vector2(325, 366),
        Vector2(151, 38), U.PINK)
    options.pressed.connect(func() -> void: get_tree().change_scene_to_file(SETTINGS))
    var quit_game := U.button(self, "QUIT", Vector2(484, 366),
        Vector2(152, 38), U.GOLD)
    quit_game.pressed.connect(func() -> void: get_tree().quit())
    var credits := U.button(self, "CREDITS", Vector2(325, 410),
        Vector2(311, 33), U.LAVENDER)
    credits.pressed.connect(func() -> void: get_tree().change_scene_to_file(CREDITS))
    U.text(self, "A tale of two spells, one room, and everything breakable.",
        Vector2(144, 471), Vector2(672, 30), 15, U.MUTED, true)
    start_button.grab_focus()


func _enter_lobby() -> void:
    get_tree().change_scene_to_file(LOBBY)
