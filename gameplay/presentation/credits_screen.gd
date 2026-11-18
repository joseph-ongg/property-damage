extends Control
const U = preload("res://gameplay/presentation/stylekit.gd")


func _ready() -> void:
    U.background(self, "help_backdrop.png")
    U.card(self, Vector2(145, 16), Vector2(669, 74), U.GOLD, 0.97)
    U.text(self, "PROJECT CREDITS", Vector2(167, 20), Vector2(625, 65),
        42, U.GOLD, true)
    U.card(self, Vector2(80, 97), Vector2(800, 361), U.LAVENDER)
    U.text(self, "UC BERKELEY  /  OPEN PROJECT  /  PROPERTY DAMAGE",
        Vector2(98, 106), Vector2(762, 34), 19, U.TEAL, true)
    U.text(self, "PROJECT MANAGEMENT",
        Vector2(112, 155), Vector2(276, 24), 18, U.GOLD)
    U.text(self, "Joseph Ong · Zander Rosenzweig",
        Vector2(405, 155), Vector2(400, 24), 17)
    U.text(self, "GAMEPLAY",
        Vector2(112, 197), Vector2(276, 24), 18, U.GOLD)
    U.text(self, "Suwen · Eva Jiang · Angela Du · Austin Liu",
        Vector2(405, 197), Vector2(425, 29), 16)
    U.text(self, "SIMULATIONS",
        Vector2(112, 240), Vector2(276, 24), 18, U.GOLD)
    U.text(self, "Jackson Weisser · Bryan Nguyen · Ethan",
        Vector2(405, 240), Vector2(420, 25), 16)
    U.text(self, "ART & AUDIO",
        Vector2(112, 283), Vector2(276, 24), 18, U.GOLD)
    U.text(self, "Annie Le · Rita Ma",
        Vector2(405, 283), Vector2(420, 25), 17)
    U.text(self, "DESIGN",
        Vector2(112, 326), Vector2(276, 24), 18, U.GOLD)
    U.text(self, "Sandra Liang · Renee Li · Shengkai Jiang",
        Vector2(405, 326), Vector2(426, 25), 16)
    U.text(self, "Additional original pixel UI drawn locally in Python.",
        Vector2(126, 383), Vector2(703, 26), 15, U.MUTED, true)
    U.text(self, "All Art Team Piskel source files are preserved with attribution.",
        Vector2(126, 408), Vector2(703, 25), 14, U.MUTED, true)
    var back := U.button(self, "BACK TO TITLE", Vector2(352, 469),
        Vector2(256, 44), U.TEAL)
    back.pressed.connect(func() -> void: _back())
    back.grab_focus()


func _back() -> void:
    get_tree().change_scene_to_file("res://gameplay/presentation/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        _back()
