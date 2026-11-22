## Reusable player prefab. Change the player_index and tint to add fighters.
class_name GameplayPlayer
extends CharacterBody2D

const GameplayInputs = preload("res://gameplay/input_actions.gd")
const MAGE1: Texture2D = preload("res://gameplay/art/mage_1.png")
const MAGE2: Texture2D = preload("res://gameplay/art/mage_2.png")
# Second full-resolution Art Team still (slide 15) used during interactions,
# Spark and optional magic. P2 is the same image recolored red.
const MAGE1_ACTION: Texture2D = preload("res://gameplay/art/mage_1_action.png")
const MAGE2_ACTION: Texture2D = preload("res://gameplay/art/mage_2_action.png")
# Both the standing original and movement frames keep their native 736x736
# texture resolution from the Art Team MidSem Character design PNG/GIF.
const P1_RUN: Array[Texture2D] = [
	preload("res://gameplay/art/mage_1_run_0.png"),
	preload("res://gameplay/art/mage_1_run_1.png"),
]
const P2_RUN: Array[Texture2D] = [
	preload("res://gameplay/art/mage_2_run_0.png"),
	preload("res://gameplay/art/mage_2_run_1.png"),
]

# Actual Art Team Piskel frames; no generated or substitute poses.
# Inspector and Angela's future character selector can call set_character_kind.
const NINJA_VISUALS: GameplayCharacterVisualSet = preload(
	"res://gameplay/characters/ninja_visuals.tres")
const WEREWOLF_VISUALS: GameplayCharacterVisualSet = preload(
	"res://gameplay/characters/werewolf_visuals.tres")
const CHARACTER_HP := {"mage": 120, "ninja": 100, "werewolf": 160}
const CHARACTER_MOVE := {"mage": 1.0, "ninja": 1.2, "werewolf": 0.85}

signal sparked(player_index: int, target: Vector2, accepted: bool)
signal interact_pressed(player_index: int, player: GameplayPlayer)
signal carry_pressed(player_index: int, player: GameplayPlayer)
signal magic_attacked(player_index: int, player: GameplayPlayer)

@export_range(1, 2) var player_index: int = 1
@export var tint: Color = Color("51d8c5")
# Art can replace either mage via the Inspector without editing Gameplay code.
# Leaving this unset keeps the original local P1/P2 prototype sprites.
@export var sprite_override: Texture2D
@export_enum("mage", "ninja", "werewolf") var character_kind: String = "mage"
@export var character_art_override: GameplayCharacterVisualSet
## Design explicitly requires a higher Ninja jump but gives no numerical
## multiplier. 1.10 is a playtest placeholder, NOT Design-approved; editable.
@export_range(1.01, 1.5, 0.01) var ninja_jump_multiplier: float = 1.10
@export_node_path("Node") var fire_bridge_path: NodePath
@export var reset_height: float = 580.0
@export var dash_enabled: bool = true  # Optional extra; off in the team MSD demo.
@export var enhanced_jumping: bool = false  # Opt in to two fixed-height jumps + airborne momentum.
## Buffer an attack pressed during its rate limit; do not discard the tap.
## One slot prevents accidental auto-repeat and still honors 0.32s fire cadence.
@export_range(0.05, 0.5, 0.01) var attack_buffer_seconds: float = 0.36
@export var platform_drop_enabled: bool = false  # Austin a529274: 可选的单向平台下穿。 / Optional one-way platform drop-through, adapted from Austin a529274.

@onready var motor: GameplayMotor = $Motor
@onready var dash: GameplayDash = $Dash
@onready var platform_drop: GameplayPlatformDrop = $PlatformDrop
@onready var sprite: Sprite2D = $Sprite2D
@onready var spark: GameplaySparkEmitter = $SparkEmitter
@onready var landing_fx: Node2D = $LandingFX
@onready var hazard: GameplayFireHazard = $FireHazard
@onready var fall_damage: GameplayFallDamage = $FallDamage
@onready var health_component: Health = $Health

var _base_motor_speed: float = 0.0
var _base_motor_jump_speed: float = 0.0
var _hurt_pose_seconds: float = 0.0
var facing: int = 1
var _spawn: Vector2
var _bridge: GameplayFireBridge
var _animation_clock: float = 0.0
var _action_pose_remaining: float = 0.0
## Source Art Team Ninja_fire is an elemental/SPARK animation only.
## Ninja G / . still launches the Design shuriken '?' projectile.
var _spark_art_pose_remaining: float = 0.0
var _spark_art_pose_elapsed: float = 0.0
var _hurt_pose_elapsed: float = 0.0
var _dash_was_active: bool = false
var _magic_cooldown: float = 0.0
var _attack_buffer_left: float = 0.0
var max_health: float = 100.0
var health: float = 100.0
var attack_damage: float = 10.0
var destroyed_objects: int = 0


func _enter_tree() -> void:
	# Each prefab registers its own controls; no bootstrapping in the arena is needed.
	GameplayInputs.register_actions()


func _ready() -> void:
	add_to_group("player_%d" % player_index)
	collision_layer = 2  # players
	collision_mask = 1   # only world; players pass through each other
	_spawn = global_position
	platform_drop.enabled = platform_drop_enabled
	if enhanced_jumping:
		motor.fixed_jump_height = true
		motor.max_jumps = 2
		motor.preserve_air_momentum = true
	_bridge = get_node_or_null(fire_bridge_path) as GameplayFireBridge
	if player_index == 2:
		facing = -1
	_base_motor_speed = motor.speed
	_base_motor_jump_speed = motor.jump_speed
	health_component.damaged.connect(_on_character_hurt)
	health_component.changed.connect(_sync_austin_health_compat)
	# Eva's individual fire and landing sensors share one authoritative Health.
	# 20 HP / 10 seconds means 1 HP per 0.5 seconds when standing in fire.
	hazard.enabled = true
	hazard.damage_interval = 0.5
	hazard.touched_fire.connect(_on_fire_contact)
	fall_damage.hard_landing.connect(_on_hard_landing)
	fall_damage.reset(self)
	set_character_kind(character_kind)
	_sync_sprite_facing()
	_apply_art_size()
	$NameTag.text = "P%d" % player_index
	$NameTag.add_theme_color_override("font_color", tint)
	$JumpCharges.visible = enhanced_jumping
	$JumpCharges.add_theme_color_override("font_color", tint)
	queue_redraw()


## Only character appearance and Design-specified HP/move scales change.
## The higher Ninja jump uses a clearly labeled, editable provisional factor;
## final numerical tuning and the Werewolf attack await Design review.
## Does not create or replace Angela's selection UI or Eva's Health logic.
func set_character_kind(kind: String) -> void:
	if not CHARACTER_HP.has(kind):
		push_warning("Unknown character: " + kind)
		return
	character_kind = kind
	if _base_motor_speed > 0.0:
		motor.speed = _base_motor_speed * float(CHARACTER_MOVE[kind])
	if _base_motor_jump_speed > 0.0:
		motor.jump_speed = _base_motor_jump_speed * (
			ninja_jump_multiplier if kind == "ninja" else 1.0)
	if health_component != null:
		health_component.max_hp = int(CHARACTER_HP[kind])
		health_component.reset()
		_sync_austin_health_compat(health_component.hp, health_component.max_hp)
	_hurt_pose_seconds = 0.0
	_hurt_pose_elapsed = 0.0
	_spark_art_pose_remaining = 0.0
	_spark_art_pose_elapsed = 0.0
	if sprite != null:
		_update_character_sprite(false)


# Compatibility views for older Austin items; do not store separate HP state.
func _sync_austin_health_compat(new_hp: int, new_max_hp: int) -> void:
	health = float(new_hp)
	max_health = float(new_max_hp)
	_update_health_label()


func _on_fire_contact() -> void:
	health_component.take_damage(1, true)


func _on_hard_landing(damage: int) -> void:
	health_component.take_damage(damage, true)


func _on_character_hurt(_amount: int) -> void:
	# Four original Art Team Ninja_injured Piskel frames @12FPS need ~0.34s.
	# Other characters keep existing Eva damage and 0.25s hurt cadence.
	_hurt_pose_seconds = 0.34 if character_kind == "ninja" else 0.25
	_hurt_pose_elapsed = 0.0
	_update_character_sprite(false)


func _character_visuals() -> GameplayCharacterVisualSet:
	if character_art_override != null:
		return character_art_override
	match character_kind:
		"ninja":
			return NINJA_VISUALS
		"werewolf":
			return WEREWOLF_VISUALS
	return null


func _physics_process(delta: float) -> void:
	var prefix := "p%d_" % player_index
	# 输入名以 p1_/p2_ 区分，两名玩家互不抢按键。
	# Prefix each action with p1_ or p2_ so the controls stay independent.
	var horizontal := Input.get_axis(prefix + "left", prefix + "right")
	var next_facing := facing
	# Lock direction for the duration of a dash; turning mid-burst feels erratic.
	if not dash.active():
		if horizontal > 0.05:
			next_facing = 1
		elif horizontal < -0.05:
			next_facing = -1
	if next_facing != facing:
		facing = next_facing
		_sync_sprite_facing()
		queue_redraw()
	var jump := Input.is_action_just_pressed(prefix + "jump")
	# 只有站在单向平台上按住下+跳才下穿，实体地板不会失效。
	# Require Down+Jump on a one-way platform; solid floors remain solid.
	if jump and Input.is_action_pressed(prefix + "down"):
		# Down+Jump is a dedicated drop attempt, never an accidental jump
		# from solid floors or an ordinary upward leap when no platform exists.
		platform_drop.try_drop(self)
		jump = false
	if dash_enabled and Input.is_action_just_pressed(prefix + "dash"):
		if dash.begin(facing):
			queue_redraw()
	var forced_x := float(dash.direction) * dash.dash_speed if dash.active() else INF
	var was_grounded := is_on_floor()
	motor.step(self, delta, horizontal, jump, forced_x, Input.is_action_just_released(prefix + "jump"), platform_drop.is_dropping())
	fall_damage.tick(self)  # Eva: must observe landing after move_and_slide().
	platform_drop.tick(self, delta)  # 离开单向平台后立即恢复原碰撞。 / Restore normal collision after dropping through a one-way platform.
	if not was_grounded and is_on_floor():
		landing_fx.trigger()
	if enhanced_jumping:
		var remaining := motor.jumps_remaining()
		var charge_text := "◆ ".repeat(remaining).strip_edges() if remaining > 0 else "·"
		if $JumpCharges.text != charge_text:
			$JumpCharges.text = charge_text
	dash.tick(delta)
	_animation_clock += delta
	_action_pose_remaining = maxf(0.0, _action_pose_remaining - delta)
	_spark_art_pose_remaining = maxf(0.0, _spark_art_pose_remaining - delta)
	_spark_art_pose_elapsed += delta
	_hurt_pose_seconds = maxf(0.0, _hurt_pose_seconds - delta)
	_hurt_pose_elapsed += delta
	var moving := absf(velocity.x) > 18.0
	if dash.active() or _dash_was_active:
		queue_redraw()
	_dash_was_active = dash.active()
	_magic_cooldown = maxf(0.0, _magic_cooldown - delta)
	if Input.is_action_just_pressed(prefix + "attack"):
		_attack_buffer_left = attack_buffer_seconds
	if _attack_buffer_left > 0.0 and _magic_cooldown <= 0.0:
		_action_pose_remaining = 0.26
		_magic_cooldown = 0.32
		_attack_buffer_left = 0.0
		magic_attacked.emit(player_index, self)
	else:
		_attack_buffer_left = maxf(0.0, _attack_buffer_left - delta)
	if Input.is_action_just_pressed(prefix + "interact"):
		_action_pose_remaining = 0.26
		interact_pressed.emit(player_index, self)
	if Input.is_action_just_pressed(prefix + "carry"):
		_action_pose_remaining = 0.26
		carry_pressed.emit(player_index, self)
	if Input.is_action_just_pressed(prefix + "spark") and spark.is_ready():
		_action_pose_remaining = 0.26
		var accepted := spark.cast_spark(global_position, facing, _bridge, tint)
		if character_kind == "ninja":
			# The source animation accompanies the real Spark cast even if
			# no flammable target is reached (flash still visibly occurs).
			# This NEVER changes G / period to a fire projectile.
			_spark_art_pose_remaining = 0.34
			_spark_art_pose_elapsed = 0.0
		sparked.emit(player_index, global_position + Vector2(facing * spark.reach, 0), accepted)
	# Process the input events first so the alternate Art Team action pose is
	# visible on the exact same physics tick as the Spark/interaction/magic.
	_update_character_sprite(moving)
	hazard.tick(delta, _bridge, self)
	# Eva FireHazard already handles player fire damage; never double-count it.
	if global_position.y > reset_height:
		global_position = _spawn
		velocity = Vector2.ZERO
		motor.reset()
		dash.reset()
		platform_drop.reset(self)
		fall_damage.reset(self)
		hazard.reset()
		_attack_buffer_left = 0.0


# Austin item compatibility: Eva Health remains the authoritative HP store.
# KO is handled by the round controller, never by an automatic respawn here.
func take_damage(amount: float, _auto_respawn: bool = true) -> void:
	health_component.take_damage(ceili(amount))


func heal(amount: float) -> void:
	health_component.heal(ceili(amount))


func reward_destruction() -> void:
	destroyed_objects += 1
	attack_damage = 10.0 * (1.0 + 0.05 * destroyed_objects)


func respawn(reset_health: bool = true) -> void:
	global_position = _spawn
	velocity = Vector2.ZERO
	if reset_health:
		health_component.reset()
	_sync_austin_health_compat(health_component.hp, health_component.max_hp)
	motor.reset()
	fall_damage.reset(self)
	hazard.reset()
	_attack_buffer_left = 0.0


func _update_health_label() -> void:
	# Health and current HP are already displayed by the arena HUD/health bar.
	# Never override the NameTag: the KO round controller owns that visual,
	# and resets it to P1/P2 on restart (Eva's Health remains authoritative).
	queue_redraw()


## Art source direction is NOT the same for all characters:
##   Ninja_side / Ninja_walk and Wolf_walk / Wolf_damage original Art
##   faces LEFT at flip_h=false. Wizard's original frames face RIGHT.
## Mirror the artwork, not the character's actual input/movement/attack.
## Verify with source Piskel frame pixels and real window direction QA.
func _sync_sprite_facing() -> void:
	if sprite == null:
		return
	var art_faces_left := character_kind == "ninja" or character_kind == "werewolf"
	sprite.flip_h = (facing > 0) if art_faces_left else (facing < 0)


func _update_character_sprite(moving: bool) -> void:
	# An Inspector override always takes priority over the PPT-derived frames.
	# When standing use the Character design static; when walking animate the
	# two original GIF frames at the deck's 80ms cadence.
	var target_texture: Texture2D = sprite_override
	if target_texture == null and _character_visuals() != null:
		var pose := "run" if moving else "idle"
		var pose_clock := _animation_clock
		if _hurt_pose_seconds > 0.0:
			pose = "hurt"
			pose_clock = _hurt_pose_elapsed
		elif character_kind == "ninja" and _spark_art_pose_remaining > 0.0:
			pose = "action"
			pose_clock = _spark_art_pose_elapsed
		elif character_kind == "werewolf" and _bridge != null and hazard != null \
				and _bridge.is_burning_world(hazard._feet_world(self)):
			# The Art Team's "Wolf walking on fire" is purely a visual
			# reaction to existing Eva/Simulation fire. No new fire damage.
			pose = "burn"
		target_texture = _character_visuals().texture_for(pose, pose_clock)
	if target_texture == null:
		if _action_pose_remaining > 0.0:
			target_texture = MAGE1_ACTION if player_index == 1 else MAGE2_ACTION
		elif moving:
			var run_frames: Array[Texture2D] = P1_RUN if player_index == 1 else P2_RUN
			target_texture = run_frames[int(_animation_clock / 0.08) % run_frames.size()]
		else:
			target_texture = MAGE1 if player_index == 1 else MAGE2
	if sprite.texture != target_texture:
		sprite.texture = target_texture
		_apply_art_size()
	# Art Team idle/run/hurt sprites must flip consistently with facing,
	# including the frames loaded while already moving in a new direction.
	_sync_sprite_facing()
	# The Art Team's original PNG has asymmetric transparent margins. Center
	# the visible robe while facing either direction; do not crop source art.
	sprite.position.x = float(facing) * 4.0 if sprite_override == null and character_kind == "mage" else 0.0
	sprite.position.y = -10.0


## Let the round controller show the actual Art Team Ninja_dead frame
## without applying the generic tilt to an already-sideways authored pose.
## Other characters retain their original KO visual.
func show_art_team_ko() -> bool:
	var set: GameplayCharacterVisualSet = _character_visuals()
	if set == null or set.dead_texture == null or sprite_override != null:
		return false
	sprite.texture = set.dead_texture
	_apply_art_size()
	# Unlike the left-facing upright Ninja, Ninja_dead's authored fallen
	# body points RIGHT. Flipping at world-left keeps KO direction coherent.
	sprite.flip_h = facing < 0
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	return true


func _apply_art_size() -> void:
	# Resize only the rendered Sprite2D, never the Art Team source texture.
	# Original 736x736 design renders as a 60px-tall mage and keeps the same
	# (unchanged) foot position and 32x64 collision shape. Inspector overrides
	# get the same visual height, regardless of the incoming PNG resolution.
	if sprite.texture != null:
		var factor := 60.0 / float(sprite.texture.get_height())
		sprite.scale = Vector2(factor, factor)


func _draw() -> void:
	# Procedural contact shadow under the interchangeable pixel-art mage.
	draw_circle(Vector2(0, 18), 12.0, Color(0.04, 0.04, 0.08, 0.38))
	draw_rect(Rect2(-16, -69, 32, 4), Color("25313b"))
	draw_rect(Rect2(-15, -68, 30.0 * health / max_health, 2), tint)
	if dash.active():
		var trail_color := Color(tint.r, tint.g, tint.b, 0.38)
		for distance: float in [19.0, 29.0, 39.0]:
			draw_line(Vector2(-facing * distance, -15), Vector2(-facing * (distance + 10), -15), trail_color, 2.0)
