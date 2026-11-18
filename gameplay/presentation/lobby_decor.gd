## Purely cosmetic arena lobby. Angela's original 55fe753 map_select.gd
## owns the actual map buttons, destinations and keyboard activation.
extends Control

const U = preload("res://gameplay/presentation/stylekit.gd")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    call_deferred("_decorate")


func _decorate() -> void:
    U.card(self, Vector2(32, 22), Vector2(896, 111), U.GOLD, 0.97)
    U.text(self, "THE DUELING HALL", Vector2(57, 34),
        Vector2(490, 54), 36, U.WHITE)
    U.text(self, "TWO FIGHTERS  /  ONE DESTRUCTIBLE WORLD",
        Vector2(60, 91), Vector2(750, 29), 15, U.TEAL)

    U.card(self, Vector2(39, 154), Vector2(437, 333), U.TEAL, 0.97)
    U.card(self, Vector2(489, 154), Vector2(433, 333), U.PINK, 0.97)
    U.text(self, "CHOOSE YOUR BATTLEGROUND",
        Vector2(66, 166), Vector2(384, 32), 20, U.TEAL, true)
    U.text(self, "CHARACTER SHOWCASE",
        Vector2(502, 167), Vector2(407, 35), 22, U.PINK, true)
    U.text(self, "Art Team character sprites",
        Vector2(502, 204), Vector2(407, 28), 14, U.MUTED, true)

    var names := ["MAGE", "NINJA", "WEREWOLF"]
    var kinds := ["mage", "ninja", "werewolf"]
    for i in range(3):
        var xpos := 503 + i * 136
        U.portrait(self, kinds[i], Vector2(xpos, 243), Vector2(126, 147))
        U.text(self, names[i], Vector2(xpos, 398),
            Vector2(126, 31), 15, U.WHITE, true)
    U.text(self, "Preview only  •  choose a map on the left",
        Vector2(507, 448), Vector2(400, 24), 13, U.MUTED, true)

    # Extension only: Angela's original two buttons and callbacks are intact.
    # The third arena is a separate optional Gameplay-owned action.
    var third := U.button(self, "CLOCKTOWER OBSERVATORY",
        Vector2(76, 423), Vector2(355, 45), U.GOLD)
    third.add_theme_font_size_override("font_size", 16)
    third.pressed.connect(func() -> void:
        get_tree().change_scene_to_file(
            "res://gameplay/observatory/observatory_level.tscn"))

    # Style existing buttons; no selection state or signal handler is changed.
    var list := get_parent().get_node("CenterContainer/VBoxContainer") as VBoxContainer
    list.add_theme_constant_override("separation", 13)
    for child in list.get_children():
        if child is Button:
            child.custom_minimum_size = Vector2(352, 60)
            child.add_theme_font_size_override("font_size", 21)
            child.add_theme_color_override("font_color", U.WHITE)
            child.add_theme_color_override("font_hover_color", U.GOLD)
            child.add_theme_stylebox_override("normal", _button_style(U.MID, U.TEAL))
            child.add_theme_stylebox_override("hover", _button_style(Color("#414d74"), U.GOLD))
            child.add_theme_stylebox_override("pressed", _button_style(U.PANEL, U.PINK))
            child.add_theme_stylebox_override("focus", _button_style(Color.TRANSPARENT, U.GOLD))
        elif child is Label:
            child.add_theme_font_size_override("font_size", 17)
            child.add_theme_color_override("font_color", U.MUTED)


func _button_style(fill: Color, accent: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = accent
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left = 7
    style.corner_radius_top_right = 7
    style.corner_radius_bottom_left = 7
    style.corner_radius_bottom_right = 7
    style.content_margin_left = 14
    style.content_margin_right = 14
    return style
