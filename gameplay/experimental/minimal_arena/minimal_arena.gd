## EXPERIMENT ONLY: NOT DESIGN APPROVED. Not linked from official game menus.
## Use existing GameplayPlayer, Eva Health and Garden projectile; no new rules.
extends Node2D

signal player_defeated(loser_index: int, winner_index: int)

@export var experimental_books_enabled: bool = false
@export var experimental_appliances_enabled: bool = false

var round_finished := false
var _spawn_positions: Dictionary = {}

func _ready() -> void:
    for index in [1, 2]:
        var player := get_node("Player%d" % index) as GameplayPlayer
        _spawn_positions[index] = player.global_position
        player.magic_attacked.connect(_on_attack)
        player.health_component.changed.connect(_on_health_changed)
        player.health_component.died.connect(_on_player_died.bind(index))
        player.hazard.enabled = false
    _update_hud()

func _on_health_changed(_hp: int, _maximum: int) -> void:
    _update_hud()

func _on_attack(_index: int, player: GameplayPlayer) -> void:
    if round_finished or not player.health_component.is_alive():
        return
    # Uses the validated Garden 10-HP hit adapter with an empty Fences node.
    var bolt := GameplayGardenMagicBolt.new()
    $Projectiles.add_child(bolt)
    bolt.initialize(player)

func _on_player_died(loser_index: int) -> void:
    if round_finished:
        return
    round_finished = true
    var loser := get_node("Player%d" % loser_index) as GameplayPlayer
    loser.sprite.rotation = 0.7 * float(loser.facing)
    loser.sprite.modulate = Color(0.72, 0.72, 0.72, 0.85)
    loser.get_node("NameTag").text = "KO"
    for index in [1, 2]:
        var fighter := get_node("Player%d" % index) as GameplayPlayer
        fighter.velocity = Vector2.ZERO
        fighter.set_physics_process(false)
    for projectile in $Projectiles.get_children():
        projectile.set_physics_process(false)
        projectile.queue_free()
    $HUD/Status.text = "P%d wins this test round. Press R to restart." % (3 - loser_index)
    player_defeated.emit(loser_index, 3 - loser_index)

func prepare_new_round() -> void:
    for projectile in $Projectiles.get_children():
        projectile.set_physics_process(false)
        projectile.queue_free()
    for index in [1, 2]:
        var player := get_node("Player%d" % index) as GameplayPlayer
        player.global_position = _spawn_positions[index]
        player.velocity = Vector2.ZERO
        player.facing = 1 if index == 1 else -1
        player.sprite.flip_h = player.facing < 0
        player.sprite.rotation = 0.0
        player.sprite.modulate = Color.WHITE
        player.get_node("NameTag").text = "P%d" % index
        player.motor.reset()
        player.dash.reset()
        player.platform_drop.reset(player)
        player._magic_cooldown = 0.0
        player.health_component.reset()
        player.set_physics_process(true)
    round_finished = false
    $HUD/Status.text = "TEST ROUND | P1: G attack | P2: . attack | R after KO"
    _update_hud()

func _update_hud() -> void:
    if not has_node("HUD/Health"):
        return
    var p1 := $Player1 as GameplayPlayer
    var p2 := $Player2 as GameplayPlayer
    $HUD/Health.text = "P1: %d/%d HP        P2: %d/%d HP" % [
        p1.health_component.hp, p1.health_component.max_hp,
        p2.health_component.hp, p2.health_component.max_hp]

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_R and round_finished:
            prepare_new_round()
            get_viewport().set_input_as_handled()
