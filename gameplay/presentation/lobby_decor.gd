## Decorative-only fantasy lobby. Angela's map_select.gd remains unchanged.
## Reads existing OptionButtons; it does not select characters or launch maps.
extends Control

const U = preload("res://gameplay/presentation/stylekit.gd")
const NOTES := {
    "mage": "ARCANIST / 120 HP\nFire magic",
    "ninja": "SHADOW / 100 HP\nShuriken",
    "werewolf": "BEAST / 160 HP\nClose combat",
}
var p1_picker: OptionButton
var p2_picker: OptionButton
var left_image: TextureRect
var right_image: TextureRect
var left_note: Label
var right_note: Label


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    call_deferred("_decorate")


func _decorate() -> void:
    var source := get_parent()
    p1_picker = source.get("player1_select") as OptionButton
    p2_picker = source.get("player2_select") as OptionButton
    if p1_picker == null or p2_picker == null:
        push_warning("Decorative portrait preview cannot find Angela's selectors")
        return
    U.text(self, "ARCANE ACADEMY  /  LOCAL VERSUS",
        Vector2(162, 24), Vector2(636, 53), 27, U.GOLD, true)
    U.text(self, "YOUR NEXT DUEL BEGINS HERE",
        Vector2(200, 77), Vector2(560, 30), 16, U.TEAL, true)
    U.card(self, Vector2(42, 153), Vector2(228, 244), U.TEAL)
    U.card(self, Vector2(691, 153), Vector2(228, 244), U.PINK)
    U.text(self, "PLAYER 1", Vector2(58, 164), Vector2(195, 30), 20, U.TEAL, true)
    U.text(self, "PLAYER 2", Vector2(710, 164), Vector2(195, 30), 20, U.PINK, true)
    left_image = U.portrait(self, "mage", Vector2(83, 198), Vector2(146, 152))
    right_image = U.portrait(self, "ninja", Vector2(733, 198), Vector2(146, 152))
    left_note = U.text(self, "", Vector2(57, 350), Vector2(201, 43), 14, U.WHITE, true)
    right_note = U.text(self, "", Vector2(701, 350), Vector2(207, 43), 14, U.WHITE, true)
    U.text(self, "Select your characters and arena using the original center controls.",
        Vector2(125, 455), Vector2(710, 34), 14, U.MUTED, true)
    p1_picker.item_selected.connect(func(_index: int) -> void: _refresh())
    p2_picker.item_selected.connect(func(_index: int) -> void: _refresh())
    _refresh()


func _refresh() -> void:
    var left := str(p1_picker.get_item_metadata(p1_picker.selected))
    var right := str(p2_picker.get_item_metadata(p2_picker.selected))
    if NOTES.has(left):
        left_image.texture = load(U.DIR + "portrait_%s.png" % left)
    if NOTES.has(right):
        right_image.texture = load(U.DIR + "portrait_%s.png" % right)
    left_note.text = NOTES.get(left, left)
    right_note.text = NOTES.get(right, right)
