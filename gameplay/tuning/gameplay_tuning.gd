## Single editable source for the final local-match Gameplay balance.
class_name GameplayTuning
extends Resource

@export_group("Combat")
@export_range(1.0, 100.0, 1.0) var base_attack_damage: float = 10.0
@export_range(0.0, 1.0, 0.01) var bonus_per_destroyed_item: float = 0.05
@export_range(0.0, 100.0, 1.0) var item_hit_damage: float = 1.0

@export_group("Fire and environmental damage")
@export_range(0.0, 100.0, 1.0) var fire_damage_per_tick: float = 2.0
@export_range(0.1, 10.0, 0.1) var fire_tick_seconds: float = 1.0
@export_range(0.1, 20.0, 0.5) var item_fire_damage_interval: float = 3.0
@export_range(0.1, 30.0, 0.5) var item_fire_duration: float = 10.0
@export_range(0.0, 500.0, 1.0) var fall_safe_distance: float = 220.0
@export_range(0.0, 1.0, 0.01) var fall_damage_per_pixel: float = 0.15

@export_group("Match")
@export_range(1, 5, 1) var rounds_to_win: int = 2
@export_range(30.0, 300.0, 5.0) var round_seconds: float = 120.0

@export_group("Projectile")
@export_range(50.0, 1000.0, 5.0) var bolt_speed: float = 395.0
@export_range(0.1, 10.0, 0.1) var bolt_lifetime: float = 1.45
