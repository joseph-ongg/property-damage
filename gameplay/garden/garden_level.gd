## Design-owned Garden arena. Separate from Angela's map selector and the
## Living Room controller; no new third arena or global gameplay rewrite.
extends Node2D

@export var experimental_books_enabled: bool = false
@export var experimental_appliances_enabled: bool = false


func _ready() -> void:
    for player_index in [1, 2]:
        var player := get_node("Player%d" % player_index) as GameplayPlayer
        player.magic_attacked.connect(_on_magic_attack)


func _on_magic_attack(_player_index: int, player: GameplayPlayer) -> void:
    var bolt := GameplayGardenMagicBolt.new()
    $Projectiles.add_child(bolt)
    bolt.initialize(player)
