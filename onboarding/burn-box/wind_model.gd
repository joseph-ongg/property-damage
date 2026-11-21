class_name WindModel
extends RefCounted


## Stable registry for local fire-wind sources.
## A source implements:
##   simulation_wind_is_active() -> bool
##   simulation_wind_direction() -> Vector2
##   simulation_wind_contains(world_point: Vector2) -> bool
## MaterialGrid discovers sources only through this registry; it never scans
## the scene tree for a device-specific node path.
static var _registered_sources: Array = []


static func register_wind_source(source: Object) -> void:
	if source == null or not is_instance_valid(source):
		return
	if not source.has_method("simulation_wind_is_active") \
		or not source.has_method("simulation_wind_direction") \
		or not source.has_method("simulation_wind_contains"):
		return
	for i in range(_registered_sources.size() - 1, -1, -1):
		if not is_instance_valid(_registered_sources[i]):
			_registered_sources.remove_at(i)
			continue
		if _registered_sources[i] == source:
			return
	_registered_sources.append(source)


static func unregister_wind_source(source: Object) -> void:
	if source == null:
		return
	for i in range(_registered_sources.size() - 1, -1, -1):
		if not is_instance_valid(_registered_sources[i]):
			_registered_sources.remove_at(i)
		elif _registered_sources[i] == source:
			_registered_sources.remove_at(i)


static func registered_wind_source_count() -> int:
	for i in range(_registered_sources.size() - 1, -1, -1):
		if not is_instance_valid(_registered_sources[i]):
			_registered_sources.remove_at(i)
	return _registered_sources.size()


static func wind_at(world_point: Vector2) -> Dictionary:
	var result := {"active": false, "direction": Vector2.ZERO}
	var combined_direction := Vector2.ZERO
	for i in range(_registered_sources.size() - 1, -1, -1):
		if not is_instance_valid(_registered_sources[i]):
			_registered_sources.remove_at(i)
			continue
		var source: Object = _registered_sources[i]
		if not bool(source.call("simulation_wind_is_active")):
			continue
		if not bool(source.call("simulation_wind_contains", world_point)):
			continue
		var direction := source.call("simulation_wind_direction") as Vector2
		if direction != Vector2.ZERO:
			combined_direction += direction.normalized()
			result.active = true
	if not combined_direction.is_zero_approx():
		result.direction = combined_direction.normalized()
	return result


static func adjusted_spread_chance(
	base_chance: float,
	wind_direction: Vector2,
	wind_strength: float,
	spread_direction: Vector2
) -> float:
	if base_chance <= 0.0:
		return 0.0
	if wind_strength == 0.0 or wind_direction == Vector2.ZERO:
		return clampf(base_chance, 0.0, 1.0)

	var normalized_wind := wind_direction.normalized()
	var normalized_spread := spread_direction.normalized()
	var alignment := normalized_wind.dot(normalized_spread)
	return clampf(base_chance * (1.0 + wind_strength * alignment), 0.0, 1.0)
