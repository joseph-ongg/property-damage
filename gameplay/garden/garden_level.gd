## Playable Garden battle using Art Team's original Garden backdrop.
## Shares real Player, Health, Simulation fire, projectile and MatchManager code
## with the Living Room; uses a deliberately smaller set of Garden props.
extends Node2D

@export var experimental_books_enabled: bool = false
@export var experimental_appliances_enabled: bool = false

const ITEM_STEMS := [
    {"name": "ROSES", "position": Vector2(280, 302), "size": Vector2(92, 74), "hp": 5.0},
    {"name": "TREE", "position": Vector2(817, 300), "size": Vector2(78, 175), "hp": 20.0},
    {"name": "MUSHROOMS", "position": Vector2(760, 449), "size": Vector2(74, 45), "hp": 5.0},
]


func _ready() -> void:
    $Player1.magic_attacked.connect(_on_attack)
    $Player2.magic_attacked.connect(_on_attack)
    for spec in ITEM_STEMS:
        var item := GameplayInteractableItem.new()
        item.name = str(spec["name"]).capitalize()
        item.item_name = str(spec["name"])
        item.position = spec["position"]
        item.hit_size = spec["size"]
        item.max_hp = spec["hp"]
        item.tags = ["flammable", "fragile"]
        $GardenItems.add_child(item)
        item.destroyed.connect(_on_item_destroyed)
        _seed_fuel(item)
    var label := Label.new()
    label.position = Vector2(18, 40)
    label.text = "GARDEN  ·  P1: WASD / F / G  ·  P2: Arrows / Enter / Period"
    label.add_theme_color_override("font_color", Color("#f5e7c4"))
    $HUD.add_child(label)


func _seed_fuel(item: GameplayInteractableItem) -> void:
    var grid: MaterialGrid = $MaterialGrid
    var bounds := item.hit_rect()
    var first := grid.world_to_cell(bounds.position)
    var last := grid.world_to_cell(bounds.end - Vector2.ONE)
    for x in range(maxi(0, first.x), mini(grid.width, last.x + 1)):
        for y in range(maxi(0, first.y), mini(grid.height, last.y + 1)):
            grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)


func _on_attack(_player_index: int, player: GameplayPlayer) -> void:
    var projectile := GameplayMagicBolt.new()
    $Projectiles.add_child(projectile)
    projectile.initialize(player)


func _on_item_destroyed(player_index: int) -> void:
    if player_index == 1 or player_index == 2:
        var attacker := get_node("Player%d" % player_index) as GameplayPlayer
        attacker.reward_destruction()
