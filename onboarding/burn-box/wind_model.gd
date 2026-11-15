class_name WindModel
extends RefCounted


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
