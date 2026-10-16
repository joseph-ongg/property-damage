## Self-contained playable MSD demo with optional quests; Sim production stays isolated.
extends Node2D

@onready var status_text: Label = $HUD/Status
@onready var fire_counter: Label = $HUD/FireCounter
@onready var cooldown_text: Label = $HUD/Cooldowns
@onready var quest_text: Label = $HUD/Quest
@onready var feedback = $Feedback
@onready var hud_frame = $HUD/Frame
@onready var victory_overlay = $VictoryOverlay

var fires_p1: int = 0
var fires_p2: int = 0
var shards_p1: int = 0
var shards_p2: int = 0
var braziers_lit: int = 0
var combo_count: int = 0
var _ui_elapsed: float = 0.0
var _world_time: float = 0.0
var _last_spark_time: float = -100.0
var _last_spark_player: int = 0
var _won: bool = false


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		get_window().content_scale_size = Vector2i(960, 540)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	$Player1.sparked.connect(_on_sparked)
	$Player2.sparked.connect(_on_sparked)
	for shard: GameplayEmberShard in $Shards.get_children():
		shard.collected.connect(_on_shard_collected.bind(shard.global_position))
	for brazier: GameplayEmberBrazier in $Braziers.get_children():
		brazier.lit_by.connect(_on_brazier_lit.bind(brazier.global_position))
	_update_hud()


func _process(delta: float) -> void:
	_world_time += delta
	_ui_elapsed += delta
	if _ui_elapsed >= 0.10:
		_ui_elapsed = 0.0
		_update_hud()


func _update_hud() -> void:
	var p1: GameplaySparkEmitter = $Player1/SparkEmitter
	var p2: GameplaySparkEmitter = $Player2/SparkEmitter
	cooldown_text.text = "P1 SPARK %s  DASH %s     P2 SPARK %s  DASH %s" % [
		_spark_state(p1), _dash_state($Player1/Dash),
		_spark_state(p2), _dash_state($Player2/Dash)]
	fire_counter.text = "SPARKS P1:%d P2:%d   DUO COMBOS:%d" % [fires_p1, fires_p2, combo_count]
	quest_text.text = "SHARDS %d/5  (P1:%d  P2:%d)      BRAZIERS %d/3" % [
		shards_p1 + shards_p2, shards_p1, shards_p2, braziers_lit]
	hud_frame.set_progress(shards_p1 + shards_p2, braziers_lit)


func _spark_state(spark: GameplaySparkEmitter) -> String:
	if spark.is_ready():
		return "READY"
	return "%.1fs" % (spark.cooldown_ratio() * spark.cooldown)


func _dash_state(dash: GameplayDash) -> String:
	return "READY" if dash.ready() else "%.1fs" % dash.cooldown_left


func _on_sparked(player_index: int, target: Vector2, accepted: bool) -> void:
	# Props are independent Gameplay objectives: missing Simulation storage must
	# not prevent a correctly aimed spark from lighting an adjacent brazier.
	var brazier_lit := false
	for brazier: GameplayEmberBrazier in $Braziers.get_children():
		if brazier.try_ignite(target, player_index):
			brazier_lit = true
	if not accepted:
		if not brazier_lit:
			status_text.text = "P%d: SPARK HAS NO VALID FIRE GRID" % player_index
			feedback.emit(target, "NO GRID", Color("99abc4"))
		else:
			feedback.emit(target, "REKINDLED!", Color("ffbf74"))
		return
	if player_index == 1:
		fires_p1 += 1
	else:
		fires_p2 += 1
	if _last_spark_player != 0 and _last_spark_player != player_index and _world_time - _last_spark_time <= 2.5:
		combo_count += 1
		status_text.text = "DUO SPARK COMBO  x%d!" % combo_count
		feedback.emit(target, "DUO COMBO +1", Color("ffe2a0"))
	else:
		var cell: Vector2i = $FireBridge.world_to_cell(target)
		status_text.text = "P%d IGNITED CELL %s" % [player_index, str(cell)] if $FireBridge.is_burning_world(target) else "P%d SPARK SENT (WAITING FOR SIMULATION)" % player_index
	feedback.emit(target, "+ SPARK", Color("f2a968"))
	_last_spark_player = player_index
	_last_spark_time = _world_time
	_update_hud()


func _on_shard_collected(player_index: int, origin: Vector2) -> void:
	if player_index == 1:
		shards_p1 += 1
	else:
		shards_p2 += 1
	status_text.text = "P%d FOUND AN EMBER SHARD" % player_index
	feedback.emit(origin, "SHARD +1", Color("ffe0a2"))
	_check_win()


func _on_brazier_lit(player_index: int, origin: Vector2) -> void:
	braziers_lit += 1
	status_text.text = "P%d RESTORED A RUIN BRAZIER" % player_index
	feedback.emit(origin + Vector2(0, -30), "REKINDLED", Color("ffb778"))
	_check_win()


func _check_win() -> void:
	_update_hud()
	if not _won and shards_p1 + shards_p2 >= 5 and braziers_lit >= 3:
		_won = true
		status_text.text = "RUINS RESTORED! ALL SHARDS AND BRAZIERS COMPLETE"
		victory_overlay.show_result(shards_p1, shards_p2, combo_count)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_R:
			# Restart is confined to the demo; production scenes own their match flow.
			get_tree().reload_current_scene()
