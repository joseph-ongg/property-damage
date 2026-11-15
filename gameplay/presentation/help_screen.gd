extends Control
const U = preload("res://gameplay/presentation/stylekit.gd")


func _ready() -> void:
    U.background(self, "help_backdrop.png")
    U.text(self, "HOW TO PLAY", Vector2(180, 22), Vector2(600, 55), 43, U.GOLD, true)
    U.text(self, "Two rivals. Destructible rooms. First to win two rounds takes the duel.",
        Vector2(95, 82), Vector2(770, 33), 17, U.WHITE, true)
    U.card(self, Vector2(53, 139), Vector2(408, 254), U.TEAL)
    U.card(self, Vector2(500, 139), Vector2(408, 254), U.PINK)
    U.text(self, "PLAYER 1  /  MINT", Vector2(73, 154), Vector2(350, 32), 23, U.TEAL)
    U.text(self, "PLAYER 2  /  CORAL", Vector2(519, 154), Vector2(350, 32), 23, U.PINK)
    U.text(self, "MOVE             A / D\nJUMP               W  (double jump)\nDROP                S + W\nATTACK            G\nSPARK                F\nPICK / THROW    C\nINTERACT           E",
        Vector2(77, 195), Vector2(360, 198), 16, U.WHITE)
    U.text(self, "MOVE             LEFT / RIGHT\nJUMP               UP  (double jump)\nDROP                DOWN + UP\nATTACK            .\nSPARK                ENTER\nPICK / THROW    ,\nINTERACT           SHIFT",
        Vector2(523, 195), Vector2(360, 198), 16, U.WHITE)
    U.text(self, "Fire spreads through flammable objects. Destroy props to gain +5% attack power.",
        Vector2(104, 414), Vector2(753, 34), 17, U.GOLD, true)
    var back := U.button(self, "BACK TO TITLE", Vector2(354, 463), Vector2(254, 44), U.LAVENDER)
    back.pressed.connect(_back)
    back.grab_focus()


func _back() -> void:
    get_tree().change_scene_to_file("res://gameplay/presentation/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        _back()
