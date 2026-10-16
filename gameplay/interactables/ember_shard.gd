## Standalone collectible. Never touches the Simulation grid.
class_name GameplayEmberShard
extends Area2D

signal collected(player_index: int)

@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 2.7

var taken: bool = false
var _clock: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if taken:
		return
	_clock += delta
	$Sprite2D.position.y = sin(_clock * bob_speed) * bob_amplitude
	$Glow.modulate.a = 0.53 + 0.19 * sin(_clock * bob_speed)


func _on_body_entered(body: Node2D) -> void:
	if taken or not body is GameplayPlayer:
		return
	collect_for(body.player_index)


func collect_for(player_index: int) -> bool:
	if taken:
		return false
	taken = true
	set_deferred("monitoring", false)  # Signals run during physics flushing.
	visible = false
	collected.emit(player_index)
	return true
