## Shared, data-driven durability and fire contract for room objects.
class_name GameplayInteractableItem
extends Node2D

const BURNING_SPRITE: Texture2D = preload("res://gameplay/msd/art/item_burning.svg")
const ASHES_SPRITE: Texture2D = preload("res://gameplay/msd/art/item_ashes.svg")

signal damaged(amount: float, source_player: int)
signal destroyed(source_player: int)

@export var item_name: String = "ITEM"
@export var tags: Array[String] = ["flammable"]
@export var max_hp: float = 5.0
@export var hit_size: Vector2 = Vector2(32, 32)
@export var hit_offset: Vector2 = Vector2.ZERO
@export var burn_damage_interval: float = 3.0
@export var burn_duration: float = 10.0

var hp: float = 0.0
var burning: bool = false
var destroyed_item: bool = false
var burned_to_ash: bool = false
var ash_visual_transferred: bool = false
var _burn_age: float = 0.0
var _burn_damage_age: float = 0.0
var _fire_contact_latched: bool = false
var _fire_damage_call: bool = false


func _ready() -> void:
	hp = max_hp
	if not tags.has("flammable"):
		tags.append("flammable")
	add_to_group("interactable_items")


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func hit_rect() -> Rect2:
	return Rect2(global_position + hit_offset - hit_size * 0.5, hit_size)


func transfer_burned_ash_visual() -> bool:
	if not destroyed_item or not burned_to_ash or ash_visual_transferred:
		return false
	ash_visual_transferred = true
	queue_redraw()
	return true


func take_damage(amount: float, source_player: int = -1) -> bool:
	if destroyed_item or amount <= 0.0 or is_inf(max_hp):
		return false
	hp = maxf(0.0, hp - amount)
	damaged.emit(amount, source_player)
	queue_redraw()
	if hp <= 0.0:
		destroyed_item = true
		burned_to_ash = _fire_damage_call
		burning = false
		destroyed.emit(source_player)
		queue_redraw()
	return true


func ignite() -> void:
	if destroyed_item or burning or not has_tag("flammable"):
		return
	burning = true
	_burn_age = 0.0
	_burn_damage_age = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if destroyed_item or not has_tag("flammable"):
		return
	var bridge: GameplayFireBridge = get_tree().get_first_node_in_group("room_fire_bridge") as GameplayFireBridge
	var touching_fire := false
	if bridge != null:
		var area := hit_rect()
		var grid: MaterialGrid = bridge.grid() as MaterialGrid
		if grid != null:
			var a := bridge.world_to_cell(area.position)
			var b := bridge.world_to_cell(area.end - Vector2.ONE)
			for x in range(maxi(a.x, 0), mini(b.x + 1, grid.width)):
				for y in range(maxi(a.y, 0), mini(b.y + 1, grid.height)):
					if grid.is_burning(x, y):
						touching_fire = true
						break
				if touching_fire:
					break
	if touching_fire and not _fire_contact_latched:
		ignite()
	_fire_contact_latched = touching_fire
	if not burning:
		return
	_burn_age += delta
	_burn_damage_age += delta
	while _burn_damage_age >= burn_damage_interval and not destroyed_item:
		_burn_damage_age -= burn_damage_interval
		_fire_damage_call = true
		take_damage(1.0)
		_fire_damage_call = false
	if _burn_age >= burn_duration:
		burning = false
		queue_redraw()


func draw_condition_bar(at: Vector2) -> void:
	if is_inf(max_hp) or hp >= max_hp or destroyed_item:
		return
	var bar := Rect2(at, Vector2(32, 4))
	draw_rect(bar, Color("302e35"))
	draw_rect(Rect2(at + Vector2.ONE, Vector2(30.0 * hp / max_hp, 2)), Color("f2b36a"))
	if burning:
		draw_rect(Rect2(at + Vector2(0, -3), Vector2(32, 2)), Color("ee6836"))


func draw_burn_sprite() -> void:
	if burned_to_ash:
		draw_texture_rect(ASHES_SPRITE, Rect2(hit_offset + Vector2(-16, hit_size.y * 0.5 - 27), Vector2(32, 32)), false)
	elif burning:
		draw_texture_rect(BURNING_SPRITE, Rect2(hit_offset + Vector2(-16, -hit_size.y * 0.5 - 21), Vector2(32, 32)), false)
