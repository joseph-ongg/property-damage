## One node that gives a player HP, hearts, fall damage and fire damage.
## Add it as a child of the player's CharacterBody2D. It builds and wires the
## Health, FallDamage, FireHazard and HeartsDisplay parts itself, and ticks them
## in its own _physics_process (which runs after the player's, so after move_and_slide).
class_name GameplayVitals
extends Node

signal died(player: CharacterBody2D)

@export var max_hp: int = 120
## Design doc: standing in fire = 20 HP over 10 s -> 1 HP every 0.5 s (2 HP/s).
@export var fire_damage_per_tick: int = 1
@export var fire_tick_interval: float = 0.5
@export var show_hearts: bool = true

var health: Health
var fall_damage: GameplayFallDamage
var fire_hazard: GameplayFireHazard
var hearts: HeartsDisplay

var _body: CharacterBody2D
var _bridge: GameplayFireBridge
var _bridge_searched: bool = false


func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	if _body == null:
		push_error("GameplayVitals must be a child of a CharacterBody2D.")
		set_physics_process(false)
		return

	health = Health.new()
	health.name = "Health"
	health.max_hp = max_hp
	add_child(health)
	health.died.connect(_on_died)

	fall_damage = GameplayFallDamage.new()
	fall_damage.name = "FallDamage"
	add_child(fall_damage)
	fall_damage.hard_landing.connect(func(dmg: int) -> void: health.take_damage(dmg, true))

	fire_hazard = GameplayFireHazard.new()
	fire_hazard.name = "FireHazard"
	fire_hazard.enabled = true
	fire_hazard.damage_interval = fire_tick_interval
	add_child(fire_hazard)
	fire_hazard.touched_fire.connect(func() -> void: health.take_damage(fire_damage_per_tick, true))

	if show_hearts:
		hearts = HeartsDisplay.new()
		hearts.name = "HeartsDisplay"
		hearts.health = health
		hearts.z_index = 10
		hearts.position = Vector2(0, -(fall_damage.height_of(_body) * 0.5 + 10.0))
		# Must be a child of the body (not of this plain Node) to follow it.
		_body.add_child.call_deferred(hearts)


func _physics_process(delta: float) -> void:
	if not _bridge_searched:
		_bridge_searched = true
		_bridge = _find_bridge(get_tree().current_scene)
		if _bridge == null:
			push_warning("GameplayVitals: no GameplayFireBridge found, fire damage disabled.")
	if health.is_alive():
		fire_hazard.tick(delta, _bridge, _body)
		fall_damage.tick(_body)


## Call when the player respawns without reloading the scene.
func reset() -> void:
	health.reset()
	fire_hazard.reset()
	fall_damage.reset(_body)


## Single entry point for other systems (thrown items, attacks).
func take_damage(amount: int, bypass_invuln: bool = false) -> bool:
	return health.take_damage(amount, bypass_invuln)


func _on_died() -> void:
	print("%s died" % _body.name)
	died.emit(_body)


func _find_bridge(node: Node) -> GameplayFireBridge:
	if node == null:
		return null
	if node is GameplayFireBridge:
		return node as GameplayFireBridge
	for child in node.get_children():
		var found := _find_bridge(child)
		if found != null:
			return found
	return null
