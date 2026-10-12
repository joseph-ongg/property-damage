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
# Prevent simultaneous local co-op inputs from toggling one appliance twice
# during the same physics frame. Players may still act on subsequent presses.
var _device_last_used_frame: Dictionary = {}


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


# 提示与实际交互共用同一套目标选择，避免 UI 提示 A、按键却触发 B。
# Hints and interactions share target selection so the shown target matches the action.
func get_interaction_offer(player: GameplayPlayer) -> Dictionary:
	var carried: GameplayBurnableProp = held_books.get(player.player_index) as GameplayBurnableProp
	if carried != null and is_instance_valid(carried) and carried.carried_by == player:
		return {"kind": "throw", "target": carried, "action": "THROW BOOK"}
	# Keep the running fan controllable while it blows a player toward nearby
	# books. Otherwise the book's higher pickup priority steals the off key.
	if experimental_appliances_enabled:
		var active_fan: GameplayAppliance = $Appliances/FanDevice
		if active_fan.switched_on and active_fan.can_interact(player):
			return {"kind": "device", "target": active_fan, "action": "TURN OFF FAN"}
	var best_distance: float = INF
	var book_target: GameplayBurnableProp = null
	if experimental_books_enabled:
		for book: GameplayBurnableProp in $Books.get_children():
			var distance: float = book.global_position.distance_to(player.global_position)
			if book.can_pick_up(player) and distance < best_distance:
				best_distance = distance
				book_target = book
	if book_target != null:
		return {"kind": "pick", "target": book_target, "action": "PICK BOOK"}
	best_distance = INF
	var device_target: GameplayAppliance = null
	if experimental_appliances_enabled:
		for device: GameplayAppliance in $Appliances.get_children():
			var distance: float = device.interaction_point().distance_to(player.global_position)
			if device.can_interact(player) and distance < best_distance:
				best_distance = distance
				device_target = device
	if device_target != null:
		return {"kind": "device", "target": device_target,
			"action": ("CLOSE " if device_target.switched_on else "OPEN ") + "FRIDGE"
				if device_target.device == GameplayAppliance.Device.FRIDGE
				else ("TURN OFF " if device_target.switched_on else "TURN ON ") + device_target.device_name()}
	return {}


func _on_interact(player_index: int, player: GameplayPlayer) -> void:
	var offer := get_interaction_offer(player)
	if offer.is_empty():
		_show_status("P%d  •  NO OBJECT IN REACH" % player_index)
		return
	var target: Node2D = offer["target"]
	match offer["kind"]:
		"throw":
			if (target as GameplayBurnableProp).throw_from(player):
				held_books.erase(player_index)
				_show_status("P%d THREW BOOK (PROTOTYPE)" % player_index)
		"pick":
			if (target as GameplayBurnableProp).pick_up(player):
				held_books[player_index] = target
				_show_status("P%d PICKED UP BOOK (PROTOTYPE)" % player_index)
		"device":
			var appliance := target as GameplayAppliance
			var device_id: int = appliance.get_instance_id()
			var current_frame: int = Engine.get_physics_frames()
			if _device_last_used_frame.get(device_id, -1) == current_frame:
				# Both actions may arrive on the same frame. Suppress only the
				# second toggle; the next deliberate press remains available.
				return
			if appliance.interact(player):
				_device_last_used_frame[device_id] = current_frame
				# An opened fridge isn't a powered-on appliance. Match the prompt's
				# OPEN/CLOSE language; other devices retain ON/OFF semantics.
				var state := ("OPEN" if appliance.switched_on else "CLOSED") if appliance.device == GameplayAppliance.Device.FRIDGE else ("ON" if appliance.switched_on else "OFF")
				_show_status("P%d  •  %s %s (PROTOTYPE)" % [player_index, appliance.device_name(), state])


func _show_status(message: String) -> void:
	status_text.text = message
	_last_status_age = 2.2


func _process(delta: float) -> void:
	if _last_status_age <= 0.0:
		return
	_last_status_age = maxf(0.0, _last_status_age - delta)
	if _last_status_age <= 0.0:
		status_text.text = "P1 F   /   P2 ENTER   •   SPARK READY"


# 火焰数据归 Simulation 管；这里仅处理演示书本/电脑视觉和状态文字。
# Simulation owns fire data; this code only handles prop visuals and status text.
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
		# Spark can reach an unburnable cell even when the Simulation grid is available.
		# Distinguish missing integration, out-of-bounds targets, and rejected ignition.
		var fire_grid: Node = $FireBridge.grid()
		if fire_grid == null or not fire_grid.has_method("ignite") or not fire_grid.has_method("world_to_cell") or not fire_grid.has_method("is_burning"):
			status_text.text = "P%d  •  FIRE GRID NOT READY" % player_index
		elif fire_grid.has_method("in_bounds") and not bool(fire_grid.call("in_bounds", cell.x, cell.y)):
			status_text.text = "P%d  •  SPARK OUTSIDE FIRE GRID" % player_index
		else:
			status_text.text = "P%d  •  CELL NOT IGNITED (MATERIAL / SIM)" % player_index
	else:
		if player_index == 1:
			sparks_p1 += 1
		else:
			sparks_p2 += 1
		if $FireBridge.is_burning_world(target):
			# A cell may have been burning before this cast; avoid claiming a new ignition.
			status_text.text = "P%d  •  CELL %s BURNING" % [player_index, str(cell)]
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
		# Consume R before reload invalidates this scene's nodes.
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
