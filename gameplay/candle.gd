extends Area2D

signal candle_toggled(lit: bool, player_index: int)

@export var lit: bool = true
@export var lit_texture: Texture2D
@export var idle_texture: Texture2D

var _in_range: Dictionary = {}  # player_index -> GameplayPlayer


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # players
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_state()


func _on_body_entered(body: Node2D) -> void:
	if body is GameplayPlayer:
		_in_range[body.player_index] = body
		if not body.interact_pressed.is_connected(_on_interact):
			body.interact_pressed.connect(_on_interact)


func _on_body_exited(body: Node2D) -> void:
	if body is GameplayPlayer:
		_in_range.erase(body.player_index)
		if body.interact_pressed.is_connected(_on_interact):
			body.interact_pressed.disconnect(_on_interact)


func _on_interact(player_index: int, _player: GameplayPlayer) -> void:
	if not _in_range.has(player_index):
		return
	lit = not lit
	_apply_state()
	candle_toggled.emit(lit, player_index)


func _apply_state() -> void:
	var tex := lit_texture if lit else idle_texture
	if tex != null:
		$Sprite2D.texture = tex
