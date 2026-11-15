## Optional Art & Audio source preview (F6); not a playable stage.
## The Piskel inputs and converted PNGs are not tied to arena colliders.
extends Control

const MAPS := [
    {"title": "Living Room (Art Team)", "texture": "res://gameplay/art_team/exported/living_room_map.png"},
    {"title": "Garden (Art Team)", "texture": "res://gameplay/art_team/exported/garden.png"},
]
const SAMPLES := [
    ["Ninja Front", "ninja_front_0.png"],
    ["Ninja Side", "ninja_side_0.png"],
    ["Ninja Walk", "ninja_walk_1.png"],
    ["Wolf Walk", "wolf_walk_0.png"],
    ["Wolf Damaged", "wolf_damage_1.png"],
    ["Mage", "mage_idle_0.png"],
    ["Mage Hurt", "mage_damage_0.png"],
    ["Mage Burning", "mage_burning_0.png"],
    ["Mage Death", "mage_death_0.png"],
    ["Fire", "fire_0.png"],
    ["Bird Drop", "bird_drop_0.png"],
]
const PREFIX := "res://gameplay/art_team/exported/"

var map_image: TextureRect
var map_title: Label
var active_map: int = 0


func _ready() -> void:
    var background := ColorRect.new()
    background.color = Color("#1c2030")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    map_image = TextureRect.new()
    map_image.position = Vector2(16, 42)
    map_image.size = Vector2(928, 325)
    map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    map_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    map_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(map_image)

    map_title = Label.new()
    map_title.position = Vector2(15, 8)
    map_title.add_theme_font_size_override("font_size", 22)
    add_child(map_title)

    var switch_button := Button.new()
    switch_button.text = "Switch Room / Garden"
    switch_button.position = Vector2(735, 8)
    switch_button.size = Vector2(200, 30)
    switch_button.pressed.connect(_switch_map)
    add_child(switch_button)

    var subtitle := Label.new()
    subtitle.position = Vector2(18, 367)
    subtitle.text = "Original Piskel artwork - gameplay collisions and combat are not previewed here"
    add_child(subtitle)

    var scroller := ScrollContainer.new()
    scroller.position = Vector2(16, 394)
    scroller.size = Vector2(928, 140)
    add_child(scroller)
    var strip := HBoxContainer.new()
    strip.add_theme_constant_override("separation", 12)
    scroller.add_child(strip)

    for sample in SAMPLES:
        var tile := VBoxContainer.new()
        tile.custom_minimum_size = Vector2(94, 115)
        var label := Label.new()
        label.text = sample[0]
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        tile.add_child(label)
        var sprite := TextureRect.new()
        sprite.custom_minimum_size = Vector2(86, 86)
        sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.texture = load(PREFIX + sample[1])
        tile.add_child(sprite)
        strip.add_child(tile)

    _show_map()


func _switch_map() -> void:
    active_map = (active_map + 1) % MAPS.size()
    _show_map()


func _show_map() -> void:
    map_image.texture = load(MAPS[active_map]["texture"])
    map_title.text = MAPS[active_map]["title"]
