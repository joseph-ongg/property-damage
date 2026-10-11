## Gameplay subteam MSD: move, jump, face the target, ignite and collide.
## This is a test harness, NOT a fabricated score, property-damage or win loop.
extends Node2D

@onready var status_text: Label = $HUD/SparkStatus

var sparks_p1: int = 0
var sparks_p2: int = 0
var _last_status_age: float = 0.0
@export var experimental_books_enabled: bool = true  # Tentative design, toggle off before integration.
@export var experimental_appliances_enabled: bool = true

var held_books: Dictionary = {}  # per-player carry state, independent of any Simulation storage


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		get_window().content_scale_size = Vector2i(960, 540)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	$Player1.sparked.connect(_on_sparked)
	$Player2.sparked.connect(_on_sparked)
	$Player1.interact_pressed.connect(_on_interact)
	$Player2.interact_pressed.connect(_on_interact)
	$Player1.magic_attacked.connect(_on_magic_attack)
	$Player2.magic_attacked.connect(_on_magic_attack)


func _physics_process(_delta: float) -> void:
	# Optional environmental forces, applied before Player._physics_process.
	for player: GameplayPlayer in [$Player1, $Player2]:
		player.motor.environment_acceleration_x = 0.0
		player.motor.speed_scale = 1.0
		if not experimental_appliances_enabled:
			continue
		var fan: GameplayAppliance = $Appliances/FanDevice
		if fan.applies_to(player):
			player.motor.environment_acceleration_x += fan.wind_acceleration
		var ac: GameplayAppliance = $Appliances/ACDevice
		if ac.applies_to(player):
			player.motor.speed_scale = ac.cold_speed_scale


func _on_magic_attack(player_index: int, player: GameplayPlayer) -> void:
	if not experimental_books_enabled and not experimental_appliances_enabled:
		return
	var projectile := GameplayMagicBolt.new()
	$Projectiles.add_child(projectile)
	projectile.initialize(player)
	projectile.hit.connect(_on_magic_hit)


func _on_magic_hit(target_name: String, player_index: int) -> void:
	_show_status("P%d  •  MAGIC HIT %s (PROTOTYPE)" % [player_index, target_name])


func _on_interact(player_index: int, player: GameplayPlayer) -> void:
	if not experimental_books_enabled and not experimental_appliances_enabled:
		return
	var carried: GameplayBurnableProp = held_books.get(player_index) as GameplayBurnableProp
	if carried != null:
		if carried.throw_from(player):
			held_books.erase(player_index)
			_show_status("P%d THREW BOOK (PROTOTYPE)" % player_index)
		return
	# Pick up the closest valid book before checking appliance interaction.
	var nearest_book: GameplayBurnableProp = null
	var best_distance: float = INF
	if experimental_books_enabled:
		for book: GameplayBurnableProp in $Books.get_children():
			var dist: float = book.global_position.distance_to(player.global_position)
			if book.can_pick_up(player) and dist < best_distance:
				best_distance = dist
				nearest_book = book
	if nearest_book != null and nearest_book.pick_up(player):
		held_books[player_index] = nearest_book
		_show_status("P%d PICKED UP BOOK (PROTOTYPE)" % player_index)
		return
	if experimental_appliances_enabled:
		var nearest_device: GameplayAppliance = null
		best_distance = INF
		for device: GameplayAppliance in $Appliances.get_children():
			var dist: float = device.global_position.distance_to(player.global_position)
			if device.can_interact(player) and dist < best_distance:
				best_distance = dist
				nearest_device = device
		if nearest_device != null and nearest_device.interact(player):
			_show_status("P%d  •  %s %s (PROTOTYPE)" % [player_index, nearest_device.device_name(), "ON" if nearest_device.switched_on else "OFF"])
			return
	_show_status("P%d  •  NO OBJECT IN REACH" % player_index)


func _show_status(message: String) -> void:
	status_text.text = message
	_last_status_age = 2.2


func _process(delta: float) -> void:
	if _last_status_age <= 0.0:
		return
	_last_status_age = maxf(0.0, _last_status_age - delta)
	if _last_status_age <= 0.0:
		status_text.text = "F / ENTER  •  SPARK"


func _on_sparked(player_index: int, target: Vector2, accepted: bool) -> void:
	# Optional prop feedback never replaces the team's Simulation ignite() call.
	var books_reacted := false
	if experimental_books_enabled:
		for books: GameplayBurnableProp in $Books.get_children():
			if books.try_scorch(target, player_index):
				books_reacted = true
	var pc_reacted := false
	if experimental_appliances_enabled:
		pc_reacted = ($Appliances/ComputerDevice as GameplayAppliance).receive_spark(target, player_index)
	var cell: Vector2i = $FireBridge.world_to_cell(target)
	if not accepted:
		status_text.text = "P%d  •  NO FIRE GRID AT TARGET" % player_index
	else:
		if player_index == 1:
			sparks_p1 += 1
		else:
			sparks_p2 += 1
		if $FireBridge.is_burning_world(target):
			status_text.text = "P%d  •  CELL %s IGNITED" % [player_index, str(cell)]
		else:
			status_text.text = "P%d  •  SPARK SENT (SIM PENDING)" % player_index
	if books_reacted:
		status_text.text = "P%d  •  BOOKS SCORCHED (VISUAL TEST)" % player_index
	elif pc_reacted:
		status_text.text = "P%d  •  COMPUTER SHORTED (VISUAL TEST)" % player_index
	_last_status_age = 2.0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if key == KEY_R and not get_tree().paused:
		get_tree().reload_current_scene()
