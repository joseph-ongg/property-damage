## Self-contained playable MSD demo bootstrap (no modifications to Sim scenes).
extends Node2D

@onready var status_text: Label = $HUD/Status
@onready var fire_counter: Label = $HUD/FireCounter
@onready var cooldown_text: Label = $HUD/Cooldowns

var fires_p1: int = 0
var fires_p2: int = 0
var _ui_elapsed: float = 0.0


func _ready() -> void:
	# Scale the gameplay viewport without modifying the team's project settings.
	if DisplayServer.get_name() != "headless":
		get_window().content_scale_size = Vector2i(960, 540)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	$Player1.sparked.connect(_on_sparked)
	$Player2.sparked.connect(_on_sparked)
	_update_hud()


func _process(delta: float) -> void:
	_ui_elapsed += delta
	if _ui_elapsed >= 0.1:
		_ui_elapsed = 0.0
		_update_hud()


func _update_hud() -> void:
	var p1: GameplaySparkEmitter = $Player1/SparkEmitter
	var p2: GameplaySparkEmitter = $Player2/SparkEmitter
	cooldown_text.text = "P1 SPARK: %s    P2 SPARK: %s" % [_spark_state(p1), _spark_state(p2)]
	fire_counter.text = "SPARKS SENT   P1: %d   P2: %d" % [fires_p1, fires_p2]


func _spark_state(spark: GameplaySparkEmitter) -> String:
	if spark.is_ready():
		return "READY"
	return "%.1fs" % (spark.cooldown_ratio() * spark.cooldown)


func _on_sparked(player_index: int, target: Vector2, accepted: bool) -> void:
	if not accepted:
		status_text.text = "P%d: NO GRID AT TARGET (OR GRID NOT CONNECTED)" % player_index
		return
	if player_index == 1:
		fires_p1 += 1
	else:
		fires_p2 += 1
	var cell: Vector2i = $FireBridge.world_to_cell(target)
	if $FireBridge.is_burning_world(target):
		status_text.text = "P%d IGNITED CELL %s" % [player_index, str(cell)]
	else:
		# A request reaching MaterialGrid does not imply that Simulation storage works yet.
		status_text.text = "P%d SPARK SENT TO %s (AWAITING SIMULATION)" % [player_index, str(cell)]
	_update_hud()
