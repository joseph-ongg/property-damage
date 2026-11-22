## Per-character sprite animations. Art can swap frames through this Resource.
## The visuals never own input, collisions, HP, or damage mechanics.
class_name GameplayCharacterVisualSet
extends Resource

@export var idle_frames: Array[Texture2D] = []
@export var run_frames: Array[Texture2D] = []
@export var jump_texture: Texture2D
@export var action_texture: Texture2D
@export var hurt_texture: Texture2D
## Optional, exactly-as-authored incoming Piskel animation sets.
## Action is used ONLY by the actual elemental Spark action, not Ninja's
## Design-defined shuriken. Existing single-image resources keep working.
@export var action_frames: Array[Texture2D] = []
@export var hurt_frames: Array[Texture2D] = []
@export var burn_frames: Array[Texture2D] = []
@export var dead_texture: Texture2D
@export_range(1.0, 24.0, 0.5) var action_fps: float = 12.0
@export_range(1.0, 24.0, 0.5) var hurt_fps: float = 12.0
@export_range(0.5, 24.0, 0.5) var burn_fps: float = 2.0
@export_range(1.0, 24.0, 0.5) var run_fps: float = 10.0
@export_range(0.5, 10.0, 0.5) var idle_fps: float = 3.0


func texture_for(pose: String, animation_time: float) -> Texture2D:
	if pose == "dead" and dead_texture != null:
		return dead_texture
	if pose == "hurt":
		if not hurt_frames.is_empty():
			return hurt_frames[posmod(int(animation_time * hurt_fps), hurt_frames.size())]
		if hurt_texture != null:
			return hurt_texture
	if pose == "action":
		if not action_frames.is_empty():
			return action_frames[posmod(int(animation_time * action_fps), action_frames.size())]
		if action_texture != null:
			return action_texture
	if pose == "burn" and not burn_frames.is_empty():
		return burn_frames[posmod(int(animation_time * burn_fps), burn_frames.size())]
	if pose == "jump" and jump_texture != null:
		return jump_texture
	var frames: Array[Texture2D] = run_frames if pose == "run" and not run_frames.is_empty() else idle_frames
	if frames.is_empty():
		return null
	var fps: float = run_fps if pose == "run" else idle_fps
	return frames[posmod(int(animation_time * fps), frames.size())]
