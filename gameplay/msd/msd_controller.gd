## Gameplay subteam room: movement, item interactions, attacks and grid fire.
## This remains a test harness without a score or win loop.
extends Node2D

const ASH_REMNANT_SCRIPT: GDScript = preload("res://gameplay/msd/ash_remnant.gd")

@onready var status_text: Label = $HUD/SparkStatus

var sparks_p1: int = 0
var sparks_p2: int = 0
var _last_status_age: float = 0.0
@export var experimental_books_enabled: bool = true  # Tentative design, toggle off before integration.
@export var experimental_appliances_enabled: bool = true

var held_items: Dictionary = {}  # per-player carry state, independent of Simulation storage
# Prevent simultaneous local co-op inputs from toggling one appliance twice
# during the same physics frame. Players may still act on subsequent presses.
var _device_last_used_frame: Dictionary = {}
var _cable_near_outlet: bool = false


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		get_window().content_scale_size = Vector2i(960, 540)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	$Player1.sparked.connect(_on_sparked)
	$Player2.sparked.connect(_on_sparked)
	$Player1.interact_pressed.connect(_on_interact)
	$Player2.interact_pressed.connect(_on_interact)
	$Player1.carry_pressed.connect(_on_carry)
	$Player2.carry_pressed.connect(_on_carry)
	$Player1.magic_attacked.connect(_on_magic_attack)
	$Player2.magic_attacked.connect(_on_magic_attack)
	_sync_fire_wind_sources()
	for item: GameplayInteractableItem in get_tree().get_nodes_in_group("interactable_items"):
		if is_ancestor_of(item):
			item.destroyed.connect(_on_item_destroyed)
			item.destroyed.connect(_on_item_ash_destroyed.bind(item))
	_seed_item_fuel()
	$MaterialGrid/FurnitureFireLayer.object_destroyed.connect(_on_object_destroyed)


func _exit_tree() -> void:
	for appliance_node in $Appliances.get_children():
		if appliance_node is GameplayAppliance:
			WindModel.unregister_wind_source(appliance_node)


func _sync_fire_wind_sources() -> void:
	for appliance_node in $Appliances.get_children():
		if appliance_node is GameplayAppliance:
			var appliance := appliance_node as GameplayAppliance
			if appliance.device in [GameplayAppliance.Device.FAN, GameplayAppliance.Device.AC]:
				appliance.simulation_fire_wind_enabled = experimental_appliances_enabled
				WindModel.register_wind_source(appliance)
			else:
				WindModel.unregister_wind_source(appliance)

func _seed_item_fuel() -> void:
	var grid: MaterialGrid = $MaterialGrid
	for item: GameplayInteractableItem in get_tree().get_nodes_in_group("interactable_items"):
		if not is_ancestor_of(item) or not item.has_tag("flammable"):
			continue
		var area := item.hit_rect()
		var a := grid.world_to_cell(area.position)
		var b := grid.world_to_cell(area.end - Vector2.ONE)
		for x in range(maxi(0, a.x), mini(grid.width, b.x + 1)):
			for y in range(maxi(0, a.y), mini(grid.height, b.y + 1)):
				if grid.get_cell_material(x, y) in [MaterialGrid.Materials.AIR, MaterialGrid.Materials.STONE]:
					grid.set_cell_material(x, y, MaterialGrid.Materials.WOOD)


func _on_item_destroyed(player_index: int) -> void:
	if player_index in [1, 2]:
		(get_node("Player%d" % player_index) as GameplayPlayer).reward_destruction()


func _on_item_ash_destroyed(_source_player: int, item: GameplayInteractableItem) -> void:
	if not is_instance_valid(item) or not item.destroyed_item or not item.burned_to_ash \
		or item.ash_visual_transferred or item.get_parent() == null:
		return
	var remnant: Node2D = ASH_REMNANT_SCRIPT.new()
	add_child(remnant)
	remnant.z_as_relative = false
	remnant.z_index = _canvas_z_index(item)
	remnant.call("initialize_from_item", item)
	item.transfer_burned_ash_visual()


func _canvas_z_index(item: CanvasItem) -> int:
	var result := item.z_index
	var child := item
	while child.z_as_relative:
		var parent := child.get_parent() as CanvasItem
		if parent == null:
			break
		result += parent.z_index
		child = parent
	return result


func _physics_process(_delta: float) -> void:
	# Keep the Simulation adapter synchronized for runtime toggles. This also
	# restores wind immediately when experimental_appliances_enabled is re-enabled.
	_sync_fire_wind_sources()
	# Optional environmental forces, applied before Player._physics_process.
	for player: GameplayPlayer in [$Player1, $Player2]:
		player.motor.environment_acceleration_x = 0.0
		player.motor.speed_scale = 1.0
		if not experimental_appliances_enabled:
			continue
		var fan: GameplayAppliance = $Appliances/FanDevice
		if fan.applies_to(player):
			player.motor.environment_acceleration_x += fan.get_fan_force_x()
		var ac: GameplayAppliance = $Appliances/ACDevice
		if ac.applies_to(player):
			player.motor.speed_scale = ac.cold_speed_scale
	var grid: MaterialGrid = $MaterialGrid
	var active_fan: GameplayAppliance = $Appliances/FanDevice
	var outlet: GameplayWorldItem = $WorldItems/Outlet
	var cable: GameplayWorldItem = $WorldItems/FanCable
	var cable_near := cable.global_position.distance_to(outlet.global_position) <= 58.0
	if not outlet.plugged and cable_near and not _cable_near_outlet and not cable.destroyed_item:
		_plug_fan_cable(cable, outlet)
	_cable_near_outlet = cable_near
	if outlet.plugged:
		cable.global_position = outlet.global_position
	var wind_carries_fire := active_fan.switched_on and _fan_has_fire(active_fan, grid)
	grid.wind_direction = Vector2(-1, 0) if wind_carries_fire and active_fan.fan_facing_left else Vector2(1, 0) if wind_carries_fire else Vector2.ZERO
	grid.wind_strength = 0.7 if wind_carries_fire else 0.0


func _plug_fan_cable(cable: GameplayWorldItem, outlet: GameplayWorldItem) -> void:
	if cable.carried_by != null:
		held_items.erase(cable.carried_by.player_index)
	cable.carried_by = null
	cable.flying = false
	cable.flight_velocity = Vector2.ZERO
	cable._reset_resting()
	cable.global_position = outlet.global_position
	cable.plugged = true
	outlet.plugged = true
	($Appliances/FanDevice as GameplayAppliance).set_fan_power(true)


func _fan_has_fire(fan: GameplayAppliance, grid: MaterialGrid) -> bool:
	if fan.burning:
		return true
	var wind_area := fan.fan_wind_local_rect()
	var a := grid.world_to_cell(fan.global_position + wind_area.position)
	var b := grid.world_to_cell(fan.global_position + wind_area.end - Vector2.ONE)
	for x in range(maxi(0, a.x), mini(grid.width, b.x + 1)):
		for y in range(maxi(0, a.y), mini(grid.height, b.y + 1)):
			if grid.is_burning(x, y) and fan.fan_wind_contains(Vector2(x + 0.5, y + 0.5) * float(grid.cell_size)):
				return true
	return false


func _on_magic_attack(player_index: int, player: GameplayPlayer) -> void:
	var projectile := GameplayMagicBolt.new()
	$Projectiles.add_child(projectile)
	projectile.initialize(player)
	projectile.hit.connect(_on_magic_hit)


func _on_magic_hit(target_name: String, player_index: int) -> void:
	_show_status("P%d  •  MAGIC HIT %s" % [player_index, target_name])


# 提示与实际交互共用同一套目标选择，避免 UI 提示 A、按键却触发 B。
# Hints and interactions share target selection so the shown target matches the action.
func get_interaction_offer(player: GameplayPlayer) -> Dictionary:
	var running_fan: GameplayAppliance = $Appliances/FanDevice
	if experimental_appliances_enabled and running_fan.switched_on and running_fan.can_interact(player):
		return {"kind": "device", "target": running_fan, "action": "TURN OFF FAN"}
	var best_distance: float = INF
	var best: Dictionary = {}
	if experimental_appliances_enabled:
		for device: GameplayAppliance in $Appliances.get_children():
			var distance: float = device.interaction_point().distance_to(player.global_position)
			if device.can_interact(player) and distance < best_distance:
				best_distance = distance
				best = {"kind": "device", "target": device,
					"action": (("CLOSE " if device.switched_on else "OPEN ") + "FRIDGE") if device.device == GameplayAppliance.Device.FRIDGE else (("TURN OFF " if device.switched_on else "TURN ON ") + device.device_name())}
	for item: GameplayWorldItem in $WorldItems.get_children():
		var distance: float = item.interaction_point().distance_to(player.global_position)
		if item.can_interact(player) and distance < best_distance:
			best_distance = distance
			best = {"kind": "item", "target": item, "action": item.action_for()}
	return best


func get_carry_offer(player: GameplayPlayer) -> Dictionary:
	var carried: GameplayBurnableProp = held_items.get(player.player_index) as GameplayBurnableProp
	if carried != null and is_instance_valid(carried) and carried.carried_by == player:
		return {"kind": "throw", "target": carried, "action": "THROW " + carried.item_name}
	var closest: GameplayBurnableProp = null
	var distance: float = INF
	for item: GameplayBurnableProp in $Books.get_children() + $WorldItems.get_children():
		if item.can_pick_up(player) and item.global_position.distance_to(player.global_position) < distance:
			closest = item
			distance = item.global_position.distance_to(player.global_position)
	if closest != null:
		return {"kind": "pick", "target": closest, "action": "PICK " + closest.item_name}
	return {}


func _on_carry(player_index: int, player: GameplayPlayer) -> void:
	var offer := get_carry_offer(player)
	if offer.is_empty():
		return
	var item: GameplayBurnableProp = offer["target"]
	if offer["kind"] == "throw" and item.throw_from(player):
		held_items.erase(player_index)
		_show_status("P%d THREW %s" % [player_index, item.item_name])
	elif offer["kind"] == "pick" and item.pick_up(player):
		held_items[player_index] = item
		_show_status("P%d PICKED UP %s" % [player_index, item.item_name])


func _on_interact(player_index: int, player: GameplayPlayer) -> void:
	var offer := get_interaction_offer(player)
	if offer.is_empty():
		_show_status("P%d  •  NO OBJECT IN REACH" % player_index)
		return
	var target: Node2D = offer["target"]
	match offer["kind"]:
		"item":
			var item := target as GameplayWorldItem
			if item.kind == GameplayWorldItem.Kind.MICROWAVE and Input.is_action_pressed("p%d_down" % player_index):
				item.toggle_microwave_power()
				_show_status("P%d  •  MICROWAVE %s" % [player_index, "ON" if item.powered else "OFF"])
			elif item.kind == GameplayWorldItem.Kind.OUTLET:
				var cable: GameplayWorldItem = $WorldItems/FanCable
				if item.plugged:
					item.plugged = false
					cable.plugged = false
					_cable_near_outlet = true
					$Appliances/FanDevice.set_fan_power(false, player_index)
					if cable.pick_up(player):
						held_items[player_index] = cable
					_show_status("P%d  •  FAN CABLE UNPLUGGED" % player_index)
			elif item.interact(player):
				_show_status("P%d  •  %s" % [player_index, item.action_for()])
		"device":
			var appliance := target as GameplayAppliance
			var device_id: int = appliance.get_instance_id()
			var current_frame: int = Engine.get_physics_frames()
			if _device_last_used_frame.get(device_id, -1) == current_frame:
				# Both actions may arrive on the same frame. Suppress only the
				# second toggle; the next deliberate press remains available.
				return
			if appliance.device == GameplayAppliance.Device.FAN and not ($WorldItems/Outlet as GameplayWorldItem).plugged:
				_show_status("P%d  •  PLUG IN FAN FIRST" % player_index)
				return
			if appliance.interact(player):
				_device_last_used_frame[device_id] = current_frame
				if appliance.device == GameplayAppliance.Device.AC and appliance.burning and appliance.switched_on:
					var grid: MaterialGrid = $MaterialGrid
					var area := appliance.hit_rect()
					var a := grid.world_to_cell(area.position)
					var b := grid.world_to_cell(area.end - Vector2.ONE)
					for x in range(maxi(0, a.x), mini(grid.width, b.x + 1)):
						for y in range(maxi(0, a.y), mini(grid.height, b.y + 1)):
							grid.extinguish(x, y)
					appliance.burning = false
					for offset in [-64.0, 64.0]:
						$FireBridge.ignite_world(appliance.global_position + Vector2(offset, 20))
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


# Simulation owns fire data; Spark also applies one hit to nearby item HP.
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
		status_text.text = "P%d  •  BOOKS DAMAGED" % player_index
	elif pc_reacted:
		status_text.text = "P%d  •  COMPUTER DAMAGED" % player_index
	_last_status_age = 2.0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if key == KEY_R and not get_tree().paused:
		# Consume R before reload invalidates this scene's nodes.
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()

const PLATFORM_FOR := {
	"BOOKSHELF": "BookshelfTop", "TABLE": "TableTop",
	"FRIDGE": "FridgeTop", "AC": "ACUpperRim",
	"PAINTING_LANDSCAPE": "GalleryFrameTop", "PAINTING_RIGHT": "SmallFrameTop",
	"WALLSHELFLEFT": "WallShelfLeft", "WALLSHELFCENTER": "WallShelfCenter",
	"WALLSHELFRIGHT": "WallShelfRight",
}
const APPLIANCE_FOR := {"FRIDGE": "FridgeDevice", "AC": "ACDevice",
	"COMPUTER": "ComputerDevice", "FAN": "FanDevice"}


func _on_object_destroyed(id: String) -> void:
	var platform := get_node_or_null(PLATFORM_FOR.get(id, ""))
	if platform != null:
		platform.set_deferred("collision_layer", 0)
	if APPLIANCE_FOR.has(id):
		($Appliances.get_node(APPLIANCE_FOR[id]) as GameplayAppliance).vanish()
	if id == "TABLE":  # everything sitting on it goes with it
		for n in ["FanDevice", "ComputerDevice"]:
			($Appliances.get_node(n) as GameplayAppliance).vanish()
	_show_status("%s BURNED DOWN" % id)
