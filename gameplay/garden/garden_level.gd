## Design-owned Garden arena. Separate from Angela's map selector and the
## Living Room controller; no new third arena or global gameplay rewrite.
extends Node2D

## Small handoff to Angela's match controller; this scene does not own the
## final best-of-three loop, winner UI, or map navigation.
signal player_defeated(loser_index: int, winner_index: int)

@export var experimental_books_enabled: bool = false
@export var experimental_appliances_enabled: bool = false


func _ready() -> void:
    for player_index in [1, 2]:
        var player := get_node("Player%d" % player_index) as GameplayPlayer
        player.magic_attacked.connect(_on_magic_attack)
        player.health_component.died.connect(_on_player_died.bind(player_index))


func _on_magic_attack(_player_index: int, player: GameplayPlayer) -> void:
    var bolt := GameplayGardenMagicBolt.new()
    $Projectiles.add_child(bolt)
    bolt.initialize(player)



func _on_player_died(loser_index: int) -> void:
    var winner_index := 3 - loser_index
    var status := get_node_or_null("HUD/Status") as Label
    if status != null:
        status.text = "P%d WINS ROUND • awaiting match-controller handoff" % winner_index
    player_defeated.emit(loser_index, winner_index)
