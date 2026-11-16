## The third reusable best-of-three arena: Observatory over the city.
extends Node2D

@export var experimental_books_enabled: bool = false
@export var experimental_appliances_enabled: bool = false

func _ready() -> void:
    $Player1.magic_attacked.connect(_on_attack)
    $Player2.magic_attacked.connect(_on_attack)
    for idx in 4:
        var crystal := GameplayObservatoryCrystal.new()
        crystal.name = "Crystal%d" % (idx + 1)
        crystal.position = Vector2(136.0 + float(idx) * 225.0, 443.0)
        crystal.hue = Color("#8ce8df") if idx % 2 == 0 else Color("#efb0e7")
        crystal.destroyed.connect(_on_crystal_destroyed.bind(crystal))
        $ArcaneProps.add_child(crystal)
    _seed_crystal_fuel()


func _seed_crystal_fuel() -> void:
    var grid: MaterialGrid = $MaterialGrid
    for crystal: GameplayObservatoryCrystal in $ArcaneProps.get_children():
        var cell := grid.world_to_cell(crystal.global_position)
        for x in range(cell.x - 1, cell.x + 2):
            for y in range(cell.y - 2, cell.y + 2):
                if grid.in_bounds(x, y):
                    grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)


func _on_attack(_index: int, player: GameplayPlayer) -> void:
    var bolt := GameplayMagicBolt.new()
    $Projectiles.add_child(bolt)
    bolt.initialize(player)


func _on_crystal_destroyed(index: int, _crystal: GameplayObservatoryCrystal) -> void:
    if index in [1, 2]:
        (get_node("Player%d" % index) as GameplayPlayer).reward_destruction()
