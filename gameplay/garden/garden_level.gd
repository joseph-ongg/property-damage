extends Node2D

const ROOM: PackedScene = preload("res://gameplay/msd/gameplay_msd.tscn")


func _ready() -> void:
	var arena: Node2D = ROOM.instantiate()
	arena.name = "GameplayMSD"
	arena.set("garden_level", true)
	add_child(arena)
