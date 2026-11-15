extends Control
const U = preload("res://gameplay/presentation/stylekit.gd")


func _ready() -> void:
    U.background(self, "help_backdrop.png")
    U.card(self, Vector2(48, 21), Vector2(864, 104), U.GOLD, 0.97)
    U.text(self, "HOW TO PLAY", Vector2(87, 34),
        Vector2(786, 52), 37, U.GOLD, true)
    U.text(self, "DESTROY PROPS  /  SURVIVE THE FIRE  /  WIN TWO ROUNDS",
        Vector2(87, 88), Vector2(786, 27), 15, U.WHITE, true)

    U.card(self, Vector2(52, 144), Vector2(414, 274), U.TEAL)
    U.card(self, Vector2(494, 144), Vector2(414, 274), U.PINK)
    U.text(self, "PLAYER 1 / MINT", Vector2(75, 154),
        Vector2(360, 30), 22, U.TEAL)
    U.text(self, "PLAYER 2 / CORAL", Vector2(518, 154),
        Vector2(360, 30), 22, U.PINK)
    U.text(self, "MOVE             A / D\nJUMP               W  (double jump)\nDROP                S + W\nATTACK            G\nSPARK                F\nPICK / THROW    C\nINTERACT           E",
        Vector2(78, 191), Vector2(360, 200), 16, U.WHITE)
    U.text(self, "MOVE             LEFT / RIGHT\nJUMP               UP  (double jump)\nDROP                DOWN + UP\nATTACK            .\nSPARK                ENTER\nPICK / THROW    ,\nINTERACT           SHIFT",
        Vector2(521, 191), Vector2(364, 200), 16, U.WHITE)
    U.text(self, "Breaking objects boosts attack by 5%. Press ESC or P to pause.",
        Vector2(105, 433), Vector2(750, 29), 15, U.GOLD, true)
    var back := U.button(self, "BACK TO TITLE", Vector2(352, 475),
        Vector2(256, 43), U.LAVENDER)
    back.pressed.connect(_back)
    back.grab_focus()


func _back() -> void:
    get_tree().change_scene_to_file("res://gameplay/presentation/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        _back()
