## Design-owned Garden arena. Separate from Angela's map selector and the
## Living Room controller; no new third arena or global gameplay rewrite.
extends Node2D

## Small handoff to Angela's match controller; this scene does not own the
## final best-of-three loop, winner UI, or map navigation.
signal player_defeated(loser_index: int, winner_index: int)

var _legacy_health_last: Dictionary = {}
var _legacy_health_carry: Dictionary = {}
var _round_finished: bool = false
var _initial_player_positions: Dictionary = {}

@export var experimental_books_enabled: bool = false
@export var experimental_appliances_enabled: bool = false


func _ready() -> void:
    # Austin's optional item base discovers a fire bridge using this
    # group. The registration belongs to this Garden scene only.
    $FireBridge.add_to_group("room_fire_bridge")
    for player_index in [1, 2]:
        var player := get_node("Player%d" % player_index) as GameplayPlayer
        player.magic_attacked.connect(_on_magic_attack)
        player.health_component.died.connect(_on_player_died.bind(player_index))
        player.health_component.changed.connect(_on_health_display_changed)
        # The shared GameplayPlayer now owns Eva's single FireHazard and
        # FallDamage. Never attach a duplicate sensor or second DoT callback.
        _initial_player_positions[player_index] = player.global_position
        _initialize_optional_legacy_health(player)
    _update_health_display()


func _on_magic_attack(_player_index: int, player: GameplayPlayer) -> void:
    if _round_finished or not player.health_component.is_alive():
        return
    var bolt := GameplayGardenMagicBolt.new()
    $Projectiles.add_child(bolt)
    bolt.initialize(player)



func _on_player_died(loser_index: int) -> void:
    if _round_finished:
        return
    _round_finished = true
    $GardenMechanics.round_active = false
    # After a round is over, pending projectiles must not inflict late hits.
    for projectile in $Projectiles.get_children():
        projectile.set_physics_process(false)
        projectile.queue_free()
    var winner_index := 3 - loser_index
    var status := get_node_or_null("HUD/Status") as Label
    if status != null:
        status.text = "P%d WINS ROUND • awaiting match-controller handoff" % winner_index
    player_defeated.emit(loser_index, winner_index)



## Minimal stand-alone HUD for Garden playtests, not Angela's shared
## match/win-screen UI. The HP values always come from Eva's Health.
func _on_health_display_changed(_hp: int, _max_hp: int) -> void:
    _update_health_display()


func _update_health_display() -> void:
    var label := get_node_or_null("HUD/PlayerHealth") as Label
    if label == null:
        return
    var p1 := $Player1 as GameplayPlayer
    var p2 := $Player2 as GameplayPlayer
    label.text = "P1  %d / %d HP     P2  %d / %d HP" % [
        p1.health_component.hp, p1.health_component.max_hp,
        p2.health_component.hp, p2.health_component.max_hp]


## Single, reusable scene contract for Angela to call at the start of a
## rematch. Angela still owns the three-round scores and menu/navigation.
## This restores ALL local gameplay state instead of only Garden props.
func prepare_new_round() -> void:
    _round_finished = true  # freeze hit resolution during the reset
    $GardenMechanics.round_active = false
    for projectile in $Projectiles.get_children():
        projectile.set_physics_process(false)
        projectile.queue_free()
    $GardenMechanics.reset_garden_for_round()
    for index in [1, 2]:
        var player := get_node("Player%d" % index) as GameplayPlayer
        player.global_position = _initial_player_positions[index]
        player.velocity = Vector2.ZERO
        player.facing = 1 if index == 1 else -1
        player.sprite.flip_h = player.facing < 0
        player.motor.reset()
        player.dash.reset()
        player.platform_drop.reset(player)
        player.hazard.reset()
        player.fall_damage.reset(player)
        # A fresh round must also reset the existing Spark emitter,
        # otherwise an already-lit flash/cooldown leaks between rounds.
        player.spark._cooldown_remaining = 0.0
        player.spark._flash_remaining = 0.0
        player.spark.queue_redraw()
        player.health_component.reset()
        player._magic_cooldown = 0.0
        _legacy_health_carry[index] = 0.0
        _on_authoritative_health_changed(
            player.health_component.hp, player.health_component.max_hp, player)
    _round_finished = false
    $GardenMechanics.round_active = true
    _update_health_display()


## Eva player-owned fire and fall sensors are active in both approved arenas.
## Older Garden-only adapters were intentionally removed to prevent applying
## DoT twice or registering two independent landing sensors.
func _physics_process(_delta: float) -> void:
    # Keep the Austin numeric alias in sync if old item code modifies it.
    for idx in [1, 2]:
        _sync_optional_legacy_damage(get_node("Player%d" % idx) as GameplayPlayer)


func _has_legacy_numeric_hp(player: GameplayPlayer) -> bool:
    if not player.has_method("take_damage"):
        return false
    for item in player.get_property_list():
        if item.get("name","") == "health":
            return true
    return false


func _initialize_optional_legacy_health(player: GameplayPlayer) -> void:
    if not _has_legacy_numeric_hp(player):
        return
    var index := player.player_index
    _legacy_health_last[index] = float(player.health_component.hp)
    _legacy_health_carry[index] = 0.0
    player.health_component.changed.connect(_on_authoritative_health_changed.bind(player))
    _on_authoritative_health_changed(
        player.health_component.hp, player.health_component.max_hp, player)


func _on_authoritative_health_changed(hp: int, max_hp: int, player: GameplayPlayer) -> void:
    if not _has_legacy_numeric_hp(player):
        return
    # Austin's deprecated HUD fields mirror Eva rather than replacing it.
    player.set("max_health", float(max_hp))
    player.set("health", float(hp))
    _legacy_health_last[player.player_index] = float(hp)
    if player.has_method("_update_health_label"):
        player.call("_update_health_label")


func _sync_optional_legacy_damage(player: GameplayPlayer) -> void:
    if not _has_legacy_numeric_hp(player):
        return
    var index := player.player_index
    var previous: float = float(_legacy_health_last.get(index,player.health_component.hp))
    var current: float = float(player.get("health"))
    if absf(previous-current) < 0.0001:
        return
    var carry := float(_legacy_health_carry.get(index,0.0))
    if current < previous:
        carry += previous - current
        var damage := floori(carry + 0.0001)
        carry -= float(damage)
        if damage > 0:
            player.health_component.take_damage(damage)
    else:
        carry = 0.0
        var healing := floori(current-previous)
        if healing > 0:
            player.health_component.heal(healing)
    _legacy_health_carry[index] = carry
    # Keep even sub-1 fractional legacy damage in the ledger, not a
    # divergent visual HP bar. Eva changes update the mirror via signal.
    _on_authoritative_health_changed(
        player.health_component.hp,player.health_component.max_hp,player)
