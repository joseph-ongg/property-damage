## Reusable player prefab. Change the player_index and tint to add fighters.
class_name GameplayPlayer
extends CharacterBody2D

signal sparked(player_index: int, target: Vector2, accepted: bool)

@export_range(1, 2) var player_index: int = 1
@export var tint: Color = Color("51d8c5")
@export_node_path("Node") var fire_bridge_path: NodePath
@export var reset_height: float = 580.0

@onready var motor: GameplayMotor = $Motor
@onready var spark: GameplaySparkEmitter = $SparkEmitter
@onready var hazard: GameplayFireHazard = $FireHazard

var facing: int = 1
var _spawn: Vector2
var _bridge: GameplayFireBridge


func _ready() -> void:
	collision_layer = 2  # players
	collision_mask = 1   # only world; players pass through each other
	_spawn = global_position
	_bridge = get_node_or_null(fire_bridge_path) as GameplayFireBridge
	if player_index == 2:
		facing = -1
	queue_redraw()


func _physics_process(delta: float) -> void:
	var prefix := "p%d_" % player_index
	var horizontal := Input.get_axis(prefix + "left", prefix + "right")
	if horizontal > 0.05:
		facing = 1
	elif horizontal < -0.05:
		facing = -1
	var jump := Input.is_action_just_pressed(prefix + "jump")
	motor.step(self, delta, horizontal, jump)
	if Input.is_action_just_pressed(prefix + "spark"):
		var accepted := spark.cast_spark(global_position, facing, _bridge, tint)
		sparked.emit(player_index, global_position + Vector2(facing * spark.reach, 0), accepted)
	hazard.tick(delta, _bridge, self)
	if global_position.y > reset_height:
		global_position = _spawn
		velocity = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	# Temporary wizard silhouette; replace with mage art without touching physics.
	var dark := tint.darkened(0.48)
	draw_rect(Rect2(-11, -19, 22, 35), dark, true)
	draw_rect(Rect2(-9, -17, 18, 30), tint, true)
	draw_rect(Rect2(-13, 12, 26, 5), dark, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -17), Vector2(0, -30), Vector2(12, -17)]), tint)
	draw_rect(Rect2(-8, -15, 16, 5), Color(0.94, 0.90, 0.78), true)
	draw_circle(Vector2(float(facing) * 6.0, -11.5), 2.0, Color("17202c"))
	draw_line(Vector2(float(facing) * 11.0, 0), Vector2(float(facing) * 17.0, -6.0), Color("e1c58f"), 3.0)
