## Original fantasy-pixel visual shell; does not own Angela's map selection.
extends Control

const U = preload("res://gameplay/presentation/stylekit.gd")
const LOBBY := "res://gameplay/presentation/fighter_select.tscn"
const HELP := "res://gameplay/presentation/help_screen.tscn"
const SETTINGS := "res://gameplay/presentation/settings_screen.tscn"
const CREDITS := "res://gameplay/presentation/credits_screen.tscn"

var start_button: Button


func _ready() -> void:
    U.background(self, "title_backdrop.png")
    # Left-aligned masthead deliberately stops before the moon in the art.
    U.card(self, Vector2(64, 49), Vector2(551, 157), U.GOLD, 0.93)
    U.text(self, "ARCANE ACADEMY", Vector2(84, 60),
        Vector2(500, 37), 20, U.GOLD)
    U.text(self, "PROPERTY DAMAGE", Vector2(82, 97),
        Vector2(515, 61), 46, U.WHITE)
    U.text(self, "REVERIE DUELS   /   LOCAL TWO-PLAYER", Vector2(85, 166),
        Vector2(493, 27), 16, U.TEAL)
    U.card(self, Vector2(96, 248), Vector2(393, 227), U.GOLD, 0.97)
    start_button = U.button(self, "LOCAL VERSUS", Vector2(119, 266),
        Vector2(347, 47), U.TEAL)
    start_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(LOBBY))
    var tutorial := U.button(self, "HOW TO PLAY", Vector2(119, 322),
        Vector2(167, 42), U.LAVENDER)
    tutorial.pressed.connect(func() -> void: get_tree().change_scene_to_file(HELP))
    var settings := U.button(self, "SETTINGS", Vector2(297, 322),
        Vector2(169, 42), U.PINK)
    settings.pressed.connect(func() -> void: get_tree().change_scene_to_file(SETTINGS))
    var credits := U.button(self, "CREDITS", Vector2(119, 373),
        Vector2(167, 42), U.LAVENDER)
    credits.pressed.connect(func() -> void: get_tree().change_scene_to_file(CREDITS))
    var quit_game := U.button(self, "QUIT", Vector2(297, 373),
        Vector2(169, 42), U.GOLD)
    quit_game.pressed.connect(func() -> void: get_tree().quit())
    U.text(self, "TWO MAGES. ONE VERY BREAKABLE WORLD.",
        Vector2(113, 428), Vector2(360, 29), 13, U.MUTED, true)
    start_button.grab_focus()
