## 来源：Austin（chouhuaidan），远端 sim/jackson/burn-box-render，a529274。
## 功能：借鉴 Down+Jump 穿过单向平台；这里改为只忽略脚下平台，不穿透实体地板。
class_name GameplayPlatformDrop
extends Node

@export var enabled: bool = false
@export_range(0.2, 1.0, 0.05) var max_pass_seconds: float = 0.7

var _platform: PhysicsBody2D = null
var _time_left: float = 0.0


func is_dropping() -> bool:
	return _platform != null and is_instance_valid(_platform)


func try_drop(player: CharacterBody2D) -> bool:
	if not enabled or is_dropping() or not player.is_on_floor():
		return false
	# 中文：从角色脚底往下探测，必须命中 one_way_collision 的平台。
	var point := player.global_position + Vector2(0, 13)
	var query := PhysicsRayQueryParameters2D.create(point, point + Vector2(0, 21), 1)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not (hit.collider is PhysicsBody2D):
		return false
	var candidate := hit.collider as PhysicsBody2D
	var one_way := false
	for child in candidate.get_children():
		if child is CollisionShape2D and child.one_way_collision and not child.disabled:
			one_way = true
			break
	if not one_way:
		return false
	_platform = candidate
	_time_left = max_pass_seconds
	player.add_collision_exception_with(_platform)
	player.global_position.y += 3.0
	player.velocity.y = maxf(player.velocity.y, 170.0)
	return true


func tick(player: CharacterBody2D, delta: float) -> void:
	if not is_dropping():
		return
	_time_left -= delta
	var clearance := false
	# 中文：整个角色低于平台底面后，再恢复碰撞；防止角色被卡回平台。
	for child in _platform.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var rect := child.shape as RectangleShape2D
			clearance = player.global_position.y - 20.0 > child.global_position.y + rect.size.y * 0.5 + 1.0
			break
	if clearance or _time_left <= 0.0:
		player.remove_collision_exception_with(_platform)
		_platform = null
		_time_left = 0.0


func reset(player: CharacterBody2D) -> void:
	if is_dropping():
		player.remove_collision_exception_with(_platform)
	_platform = null
	_time_left = 0.0
