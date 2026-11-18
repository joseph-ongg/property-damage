## Design-owned Garden arena. Separate from Angela's map selector and the
## Living Room controller; no new third arena or global gameplay rewrite.
extends Node2D

## Small handoff to Angela's match controller; this scene does not own the
## final best-of-three loop, winner UI, or map navigation.
signal player_defeated(loser_index: int, winner_index: int)

var _legacy_health_last: Dictionary = {}
var _legacy_health_carry: Dictionary = {}

@export var experimental_books_enabled: bool = false
@export var experimental_appliances_enabled: bool = false


func _ready() -> void:
    for player_index in [1, 2]:
        var player := get_node("Player%d" % player_index) as GameplayPlayer
        player.magic_attacked.connect(_on_magic_attack)
        player.health_component.died.connect(_on_player_died.bind(player_index))
        # Eva's FireHazard sensor already samples the player's feet, and the
        # Garden carries the upstream Simulation bridge. Enable it only for
        # this arena; do not change the shared player prefab or Living Room.
        player.hazard.enabled = true
        player.hazard.damage_interval = 1.0
        player.hazard.touched_fire.connect(_on_player_fire_contact.bind(player))
        _attach_optional_eva_fall_damage(player)
        _initialize_optional_legacy_health(player)


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



## The Design requires 20 HP fire damage over 10 seconds. The existing
## sensor ticks once per second; Eva's newer Health offers bypass_invuln
## for DOT while main's earlier Health has only a one-argument API.
func _on_player_fire_contact(player: GameplayPlayer) -> void:
    if not is_instance_valid(player) or not player.health_component.is_alive():
        return
    var hit_method_args := 1
    for entry in player.health_component.get_method_list():
        if entry.get("name", "") == "take_damage":
            hit_method_args = (entry.get("args", []) as Array).size()
            break
    if hit_method_args >= 2:
        player.health_component.callv("take_damage", [2, true])
    else:
        player.health_component.take_damage(2)


## Load Eva's unmerged fall damage component only when it exists. The
## implementation stays Eva-owned; no copy-paste of its calculations.
func _attach_optional_eva_fall_damage(player: GameplayPlayer) -> void:
    var path := "res://gameplay/components/fall_damage.gd"
    if not ResourceLoader.exists(path):
        return
    var source := load(path) as GDScript
    if source == null:
        return
    var sensor := source.new() as Node
    sensor.name = "EvaFallDamageGarden"
    player.add_child(sensor)
    sensor.hard_landing.connect(_on_player_fall_damage.bind(player))
    sensor.reset(player)


func _physics_process(_delta: float) -> void:
    # Austin's legacy numeric HP must never become an independent second
    # life meter in the Garden. Convert any external change into Eva Health.
    for idx in [1, 2]:
        _sync_optional_legacy_damage(get_node("Player%d" % idx) as GameplayPlayer)
    # Sensor is attached only when Eva's class has actually been merged.
    # Update after Player movement by using its last completed transform.
    for idx in [1, 2]:
        var player := get_node("Player%d" % idx) as GameplayPlayer
        var sensor := player.get_node_or_null("EvaFallDamageGarden")
        if sensor != null and sensor.has_method("tick"):
            sensor.tick(player)


func _on_player_fall_damage(amount: int, player: GameplayPlayer) -> void:
    if amount <= 0 or not is_instance_valid(player):
        return
    # All Health components support the one-argument fall callback.
    # Eva's newer component adds optional DOT bypass below.
    var can_bypass := false
    for entry in player.health_component.get_method_list():
        if entry.get("name", "") == "take_damage":
            can_bypass = (entry.get("args", []) as Array).size() >= 2
            break
    if can_bypass:
        player.health_component.callv("take_damage", [amount, true])
    else:
        player.health_component.take_damage(amount)



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
