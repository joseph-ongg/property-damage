## Garden MVP with accurate integer pixel scaling, destructible original
## Piskel plant layers, and Art-pixel-derived flammable Simulation cells.
## Shares the actual Character/Health, item damage, projectile, grid, and
## best-of-three MatchManager with Living Room.
extends Node2D

@export var experimental_books_enabled: bool = false
@export var experimental_appliances_enabled: bool = false

const FUEL_TEXTURE: Texture2D = preload("res://gameplay/garden/art_generated/garden_fuel_mask.png")
# Three Art Team flower, trunk and mushroom silhouettes split from the
# original background. Keep names for external tests/integration contract.
const ITEMS := [
    {"name":"Roses", "kind":"rose", "label":"ROSES", "position":Vector2(210, 243),
        "hit_size":Vector2(305, 358), "hp":10.0},
    {"name":"Tree", "kind":"tree", "label":"TREE",  "position":Vector2(731, 238),
        "hit_size":Vector2(360, 476), "hp":25.0},
    {"name":"Mushrooms", "kind":"mushrooms", "label":"MUSHROOMS", "position":Vector2(562, 441),
        "hit_size":Vector2(328, 60), "hp":7.0},
]

const MARKERS := {"rose": Color.RED, "tree": Color.GREEN, "mushrooms": Color.BLUE}
var _fuel_mask: Image
var _material_at_start: Dictionary = {}


func _ready() -> void:
    $Player1.magic_attacked.connect(_on_attack)
    $Player2.magic_attacked.connect(_on_attack)
    _fuel_mask = FUEL_TEXTURE.get_image()
    _seed_fuel()
    for spec in ITEMS:
        var item := GameplayGardenProp.new()
        item.name = str(spec["name"])
        item.item_name = str(spec["label"])
        item.motif = str(spec["kind"])
        item.position = spec["position"]
        item.hit_size = spec["hit_size"]
        item.max_hp = float(spec["hp"])
        item.tags = ["flammable", "fragile"]
        $GardenItems.add_child(item)
        item.destroyed.connect(_on_item_destroyed.bind(item))


func _seed_fuel() -> void:
    var grid: MaterialGrid = $MaterialGrid
    # Mask was computed from actual rose/tree/mushroom source pixels; air
    # and the stone fence are never repainted as giant flammable rectangles.
    for x in grid.width:
        for y in grid.height:
            var pigment := _fuel_mask.get_pixel(x, y)
            if pigment.r > 0.9 or pigment.g > 0.9 or pigment.b > 0.9:
                grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)


func _clear_prop_fuel(prop: GameplayGardenProp) -> void:
    var pigment: Color = MARKERS.get(prop.motif, Color.TRANSPARENT)
    var grid: MaterialGrid = $MaterialGrid
    for x in grid.width:
        for y in grid.height:
            var cell_color := _fuel_mask.get_pixel(x, y)
            if cell_color == pigment and grid.get_cell_material(x, y) == MaterialGrid.Materials.WOOD:
                grid.set_cell_material(x, y,
                    MaterialGrid.Materials.ASH if prop.burned_to_ash else MaterialGrid.Materials.AIR)


func _on_attack(_player_index: int, player: GameplayPlayer) -> void:
    var projectile := GameplayMagicBolt.new()
    $Projectiles.add_child(projectile)
    projectile.initialize(player)


func _on_item_destroyed(player_index: int, prop: GameplayGardenProp) -> void:
    _clear_prop_fuel(prop)
    if player_index in [1, 2]:
        var player := get_node("Player%d" % player_index) as GameplayPlayer
        player.reward_destruction()
