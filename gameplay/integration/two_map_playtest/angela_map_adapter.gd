## Playtest-only adapter: reuse Angela's actual two-button map selector scene.
## The owner's original script and scene remain unchanged.
extends "res://gameplay/MapSelection/map_select.gd"

signal playtest_map_selected(scene_path: String)

func _load_map(path: String) -> void:
    if path == "res://gameplay/LevelSelection/GardenPlaceholder.tscn":
        path = "res://gameplay/garden/garden_level.tscn"
    playtest_map_selected.emit(path)
