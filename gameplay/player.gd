## Reusable player prefab. Change the player_index and tint to add fighters.
class_name GameplayPlayer
extends CharacterBody2D

const GameplayInputs = preload("res://gameplay/input_actions.gd")
const MAGE1: Texture2D = preload("res://gameplay/art/mage_1.png")
const MAGE2: Texture2D = preload("res://gameplay/art/mage_2.png")

signal sparked(player_index: int, target: Vector2, accepted: bool)

@export_range(1, 2) var player_index: int = 1
@export var tint: Color = Color("51d8c5")
@export_node_path("Node") var fire_bridge_path: NodePath
@export var reset_height: float = 580.0

@onready var motor: GameplayMotor = $Motor
@onready var dash: GameplayDash = $Dash
@onready var sprite: Sprite2D = $Sprite2D
@onready var spark: GameplaySparkEmitter = $SparkEmitter
@onready var hazard: GameplayFireHazard = $FireHazard

var facing: int = 1
var _spawn: Vector2
var _bridge: GameplayFireBridge
var _animation_clock: float = 0.0
var _dash_was_active: bool = false


func _enter_tree() -> void:
	# Each prefab registers its own controls; no bootstrapping in the arena is needed.
	GameplayInputs.register_actions()


func _ready() -> void:
	collision_layer = 2  # players
	collision_mask = 1   # only world; players pass through each other
	_spawn = global_position
	_bridge = get_node_or_null(fire_bridge_path) as GameplayFireBridge
	if player_index == 2:
		facing = -1
	sprite.texture = MAGE1 if player_index == 1 else MAGE2
	sprite.flip_h = facing < 0
	$NameTag.text = "P%d" % player_index
	$NameTag.add_theme_color_override("font_color", tint)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var prefix := "p%d_" % player_index
	var horizontal := Input.get_axis(prefix + "left", prefix + "right")
	var next_facing := facing
	if horizontal > 0.05:
		next_facing = 1
	elif horizontal < -0.05:
		next_facing = -1
	if next_facing != facing:
		facing = next_facing
		sprite.flip_h = facing < 0
		queue_redraw()
	var jump := Input.is_action_just_pressed(prefix + "jump")
	if Input.is_action_just_pressed(prefix + "dash"):
		if dash.begin():
			queue_redraw()
	var forced_x := float(facing) * dash.dash_speed if dash.active() else INF
	motor.step(self, delta, horizontal, jump, forced_x)
	dash.tick(delta)
	_animation_clock += delta
	var moving := is_on_floor() and absf(velocity.x) > 18.0
	sprite.position.y = -2.0 + (sin(_animation_clock * 17.0) * 1.0 if moving else 0.0)
	if dash.active() or _dash_was_active:
		queue_redraw()
	_dash_was_active = dash.active()
	if Input.is_action_just_pressed(prefix + "spark") and spark.is_ready():
		var accepted := spark.cast_spark(global_position, facing, _bridge, tint)
		sparked.emit(player_index, global_position + Vector2(facing * spark.reach, 0), accepted)
	hazard.tick(delta, _bridge, self)
	if global_position.y > reset_height:
		global_position = _spawn
		velocity = Vector2.ZERO
		motor.reset()
		dash.reset()


func _draw() -> void:
	# Procedural contact shadow under the interchangeable pixel-art mage.
	draw_circle(Vector2(0, 18), 12.0, Color(0.04, 0.04, 0.08, 0.38))
	if dash.active():
		var trail_color := Color(tint.r, tint.g, tint.b, 0.38)
		for distance: float in [19.0, 29.0, 39.0]:
			draw_line(Vector2(-facing * distance, -15), Vector2(-facing * (distance + 10), -15), trail_color, 2.0)
