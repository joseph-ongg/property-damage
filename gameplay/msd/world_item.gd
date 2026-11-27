## Configurable room object. New prop types can reuse the same tags and HP rules.
class_name GameplayWorldItem
extends GameplayBurnableProp

enum Kind { CLOCK, PAINTING, MICROWAVE, OUTLET, TRASHCAN, PLUSHIE, PLANT, BOOKSHELF, FOOD, CABLE }

@export var kind: Kind = Kind.CLOCK
@export var food_heal: float = 20.0
@export var use_kind_defaults: bool = true

var opened: bool = false
var powered: bool = false
var plugged: bool = false
var contents: int = 3
var cook_age: float = 0.0
var warm: bool = false
var _trash_cooldowns: Dictionary = {}
var _shards_active: bool = false
var _shard_hits: Dictionary = {}
var removed_from_fridge: bool = false
var _prior_trash_feet: Dictionary = {}


func _ready() -> void:
	if use_kind_defaults:
		_apply_kind_defaults()
	width = hit_size.x
	super._ready()
	if kind == Kind.FOOD:
		(get_node("../../Appliances/FridgeDevice") as GameplayAppliance).state_changed.connect(func(_device: int, _state: bool, _player: int) -> void: queue_redraw())


func _apply_kind_defaults() -> void:
	match kind:
		Kind.CLOCK:
			item_name = "CLOCK"; max_hp = 5; hit_size = Vector2(44, 44); tags = ["flammable", "throwable", "fragile"]
		Kind.PAINTING:
			item_name = "PAINTING"; max_hp = 3; hit_size = Vector2(66, 48); tags = ["flammable", "throwable", "fragile"]
		Kind.MICROWAVE:
			item_name = "MICROWAVE"; max_hp = 8; hit_size = Vector2(62, 44); tags = ["flammable"]
		Kind.OUTLET:
			item_name = "OUTLET"; max_hp = INF; hit_size = Vector2(18, 22); tags = ["flammable"]
		Kind.TRASHCAN:
			item_name = "TRASHCAN"; max_hp = 5; hit_size = Vector2(38, 52); tags = ["flammable"]
		Kind.PLUSHIE:
			item_name = "PLUSHIE"; max_hp = 3; hit_size = Vector2(32, 30); tags = ["flammable", "throwable"]
		Kind.PLANT:
			item_name = "PLANT"; max_hp = 5; hit_size = Vector2(32, 48); tags = ["flammable", "throwable", "fragile"]
		Kind.BOOKSHELF:
			item_name = "BOOKSHELF"; max_hp = INF; hit_size = Vector2(184, 138); tags = ["flammable"]
		Kind.FOOD:
			item_name = "FOOD"; max_hp = 1; hit_size = Vector2(18, 14); tags = ["flammable", "throwable", "fragile"]
		Kind.CABLE:
			item_name = "FAN CABLE"; max_hp = 5; hit_size = Vector2(14, 14); tags = ["flammable", "throwable"]


func can_interact(player: GameplayPlayer) -> bool:
	if kind == Kind.FOOD and not removed_from_fridge and not (get_node("../../Appliances/FridgeDevice") as GameplayAppliance).switched_on:
		return false
	if kind == Kind.OUTLET and not plugged:
		return false
	return not destroyed_item and kind in [Kind.MICROWAVE, Kind.OUTLET, Kind.FOOD, Kind.BOOKSHELF] and interaction_point().distance_to(player.global_position) <= 72.0 and GameplayInteractionLOS.has_path(player, interaction_point())


func interaction_point() -> Vector2:
	if kind == Kind.MICROWAVE:
		return global_position + Vector2(-32, 99)
	return global_position


func can_pick_up(player: GameplayPlayer) -> bool:
	if kind == Kind.CABLE and plugged:
		return false
	if kind == Kind.FOOD and not removed_from_fridge and not (get_node("../../Appliances/FridgeDevice") as GameplayAppliance).switched_on:
		return false
	return super.can_pick_up(player)


func pick_up(player: GameplayPlayer) -> bool:
	if not super.pick_up(player):
		return false
	if kind == Kind.FOOD:
		removed_from_fridge = true
	return true


func action_for() -> String:
	match kind:
		Kind.MICROWAVE:
			if opened:
				return "TAKE NUGGET" if contents > 0 else "CLOSE MICROWAVE"
			return "OPEN MICROWAVE"
		Kind.OUTLET: return "UNPLUG FAN CABLE" if plugged else "OUTLET"
		Kind.FOOD: return "EAT FOOD"
		Kind.BOOKSHELF: return "CLIMB BOOKSHELF"
	return "INTERACT"


func interact(player: GameplayPlayer) -> bool:
	if not can_interact(player):
		return false
	match kind:
		Kind.MICROWAVE:
			if opened:
				if contents > 0:
					contents -= 1
					player.heal(50.0 if warm else 20.0)
				else:
					opened = false
			else:
				opened = true
				powered = false
		Kind.FOOD:
			player.heal(food_heal)
			take_damage(hp)
		Kind.BOOKSHELF:
			player.global_position = Vector2(global_position.x, global_position.y - hit_size.y * 0.5 - 34.0)
			player.velocity = Vector2.ZERO
	queue_redraw()
	return true


func _trap_player(player: GameplayPlayer) -> void:
	if _trash_cooldowns.has(player.player_index):
		return
	_trash_cooldowns[player.player_index] = true
	player.take_damage(25.0, false)
	player.set_physics_process(false)
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		if is_instance_valid(player):
			player.respawn(player.health <= 0.0)
			player.set_physics_process(true)
		_trash_cooldowns.erase(player.player_index), CONNECT_ONE_SHOT)


func toggle_microwave_power() -> void:
	if kind != Kind.MICROWAVE or destroyed_item:
		return
	if opened:
		opened = false
	elif contents > 0:
		powered = not powered
		if powered:
			cook_age = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	super._process(delta)
	if powered and kind == Kind.MICROWAVE and not destroyed_item:
		cook_age += delta
		if cook_age >= 10.0:
			warm = true
			powered = false
			queue_redraw()
	if kind == Kind.TRASHCAN:
		var rim_y := global_position.y - hit_size.y * 0.5
		for player: GameplayPlayer in [get_tree().get_first_node_in_group("player_1") as GameplayPlayer, get_tree().get_first_node_in_group("player_2") as GameplayPlayer]:
			if player == null:
				continue
			var feet_y := player.global_position.y + 18.0
			var previous: float = _prior_trash_feet.get(player.player_index, feet_y)
			_prior_trash_feet[player.player_index] = feet_y
			if player.velocity.y > 0.0 and previous <= rim_y and feet_y >= rim_y and absf(player.global_position.x - global_position.x) < hit_size.x * 0.35:
				_trap_player(player)
	if _shards_active:
		for player: GameplayPlayer in [get_tree().get_first_node_in_group("player_1") as GameplayPlayer, get_tree().get_first_node_in_group("player_2") as GameplayPlayer]:
			if player != null and not _shard_hits.has(player.player_index) and player.global_position.distance_to(global_position) < 24.0:
				_shard_hits[player.player_index] = true
				player.take_damage(5.0)
	if kind == Kind.CABLE:
		queue_redraw()


func _break_from_throw() -> void:
	super._break_from_throw()
	if kind == Kind.PLANT:
		_shards_active = true
		queue_redraw()


# The room's authored Clock, Painting, Microwave, shelves and appliances
# retain their existing art. Separate Art textures are still missing for
# these small interactive tokens; never invent final object illustrations.
func _draw_missing_art_marker() -> void:
	var c := Color("#717f93")
	if burning:
		c = Color("#ba6550")
	if destroyed_item:
		c = Color("#56585a")
	draw_rect(Rect2(-11, -15, 22, 22), c)
	draw_rect(Rect2(-11, -15, 22, 22), Color("#f0eade"), false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(-4.5, 1.5), "?",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#fff8ee"))


func _draw() -> void:
	if ash_visual_transferred:
		return
	if kind == Kind.FOOD and not removed_from_fridge and not (get_node("../../Appliances/FridgeDevice") as GameplayAppliance).switched_on:
		return
	if burned_to_ash:
		draw_rect(Rect2(-hit_size.x * 0.35, hit_size.y * 0.3, hit_size.x * 0.7, 6), Color("514b49"))
		draw_rect(Rect2(-hit_size.x * 0.25, hit_size.y * 0.3 - 4, hit_size.x * 0.5, 4), Color("77706a"))
		draw_burn_sprite()
		return
	if kind in [Kind.OUTLET, Kind.TRASHCAN, Kind.PLUSHIE, Kind.PLANT, Kind.FOOD]:
		_draw_missing_art_marker()
		if kind == Kind.PLANT and _shards_active:
			# Even broken shards have no supplied Art. The hazard stays active,
			# but its visual must remain a clear placeholder, not fake pottery.
			for offset in [-19.0, 13.0]:
				draw_rect(Rect2(offset, 10, 9, 9), Color("#717f93"))
				draw_string(ThemeDB.fallback_font, Vector2(offset+1, 18), "?",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#ffffff"))
		draw_condition_bar(Vector2(-16, -hit_size.y * 0.5 - 11))
		draw_burn_sprite()
		return
	var c := Color("8d6654")
	if burning: c = Color("ad5940")
	if destroyed_item: c = Color("494344")
	match kind:
		Kind.CLOCK:
			draw_circle(Vector2.ZERO, 21, c)
			draw_circle(Vector2.ZERO, 17, Color("d8c6a4") if not destroyed_item else c)
			draw_line(Vector2.ZERO, Vector2(0, -11), Color("443c42"), 2)
			draw_line(Vector2.ZERO, Vector2(8, 5), Color("443c42"), 2)
		Kind.PAINTING:
			draw_rect(Rect2(-33, -24, 66, 48), c)
			draw_rect(Rect2(-28, -19, 56, 38), Color("608c87") if not destroyed_item else c)
			draw_line(Vector2(-25, 12), Vector2(3, -13), Color("e5c18c"), 5)
		Kind.MICROWAVE:
			# The closed microwave is already painted on TEAM_FRIDGE.
			if opened:
				draw_rect(Rect2(-24, -12, 39, 23), Color("283c43"))
			draw_rect(Rect2(23, -8, 5, 5), Color("e4a454") if powered else Color("b4c1b5"))
			if opened:
				for i in contents:
					draw_rect(Rect2(-21 + i * 11, 3, 8, 5), Color("e4ae63"))
		Kind.OUTLET:
			draw_rect(Rect2(-9, -11, 18, 22), Color("d6cfbc"))
			draw_rect(Rect2(-4, -4, 2, 5), Color("555761"))
			draw_rect(Rect2(2, -4, 2, 5), Color("555761"))
		Kind.TRASHCAN:
			draw_rect(Rect2(-19, -26, 38, 52), c)
			draw_rect(Rect2(-22, -28, 44, 6), Color("d0a67c"))
		Kind.PLUSHIE:
			draw_circle(Vector2(0, 1), 14, c)
			draw_circle(Vector2(-9, -10), 6, c)
			draw_circle(Vector2(9, -10), 6, c)
		Kind.PLANT:
			draw_rect(Rect2(-14, 5, 28, 17), c)
			if _shards_active:
				draw_rect(Rect2(-22, 17, 8, 5), Color("9a7259"))
				draw_rect(Rect2(12, 18, 9, 4), Color("9a7259"))
			if not destroyed_item:
				draw_line(Vector2(0, 5), Vector2(0, -23), Color("5f9d70"), 4)
				draw_circle(Vector2(-9, -16), 8, Color("6aab72"))
				draw_circle(Vector2(9, -18), 8, Color("6aab72"))
		Kind.BOOKSHELF:
			# Artwork already exists in the room texture; show condition through a bar.
			pass
		Kind.FOOD:
			draw_rect(Rect2(-9, -7, 18, 14), Color("9fba69") if not destroyed_item else c)
		Kind.CABLE:
			var fan: GameplayAppliance = get_node("../../Appliances/FanDevice") as GameplayAppliance
			# Functional cable route stays visible. Plug art is not supplied.
			draw_line(Vector2.ZERO, fan.global_position - global_position, Color("333942"), 3.0)
			_draw_missing_art_marker()
	draw_condition_bar(Vector2(-16, -hit_size.y * 0.5 - 11))
	draw_burn_sprite()
