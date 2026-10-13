## Subtle room glows react to the actual appliance states.
## This visual layer has no physics or material storage.
extends Node2D

const COMPUTER_LIGHT: Texture2D = preload("res://gameplay/msd/art/living_room_computer_glow.png")
const AC_LIGHT: Texture2D = preload("res://gameplay/msd/art/living_room_ac_glow.png")

@export var computer_path: NodePath = NodePath("../Appliances/ComputerDevice")
@export var ac_path: NodePath = NodePath("../Appliances/ACDevice")
@export_range(0.1, 10.0, 0.1) var fade_speed: float = 3.0

var computer_intensity: float = 0.0
var ac_intensity: float = 0.0
var _computer: GameplayAppliance
var _ac: GameplayAppliance

func _ready() -> void:
	_computer = get_node_or_null(computer_path) as GameplayAppliance
	_ac = get_node_or_null(ac_path) as GameplayAppliance
	set_process(_computer != null or _ac != null)

func _process(delta: float) -> void:
	var computer_target := 1.0 if _computer != null and _computer.switched_on and not _computer.charred else 0.0
	var ac_target := 1.0 if _ac != null and _ac.switched_on and not _ac.charred else 0.0
	var next_computer := move_toward(computer_intensity, computer_target, fade_speed * delta)
	var next_ac := move_toward(ac_intensity, ac_target, fade_speed * delta)
	if not is_equal_approx(next_computer, computer_intensity) or not is_equal_approx(next_ac, ac_intensity):
		computer_intensity = next_computer
		ac_intensity = next_ac
		queue_redraw()

func _draw() -> void:
	if computer_intensity > 0.0:
		draw_texture(COMPUTER_LIGHT, Vector2.ZERO, Color(1.0, 1.0, 1.0, computer_intensity))
	if ac_intensity > 0.0:
		draw_texture(AC_LIGHT, Vector2.ZERO, Color(1.0, 1.0, 1.0, ac_intensity))
