## Art team can set character sprites and collision dimensions on instances
## without modifying GameplayPlayer's movement or Spark implementation.
extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _run() -> void:
	var prefab: PackedScene = load("res://gameplay/prefabs/gameplay_player.tscn")
	check(prefab != null, "Gameplay prefab has its own team-safe path")
	if prefab == null:
		quit(1)
		return
	var standalone: GameplayPlayer = prefab.instantiate()
	standalone.player_index = 1
	standalone.sprite_override = preload("res://gameplay/art/mage_2.png")
	root.add_child(standalone)
	await physics_frame
	var art: Sprite2D = standalone.get_node("Sprite2D")
	check(art.texture == standalone.sprite_override, "Art-selected texture survives player initialization")
	check(standalone.player_index == 1 and standalone.get_node("NameTag").text == "P1", "Art override does not alter player identity")
	check(standalone.collision_layer == 2 and standalone.collision_mask == 1, "Art override preserves collision contract")
	check(standalone.motor != null and standalone.spark != null, "Art override preserves movement and Spark modules")
	standalone.queue_free()

	var main := (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await physics_frame
	var p1: GameplayPlayer = main.get_node("GameplayMSD/Player1")
	var p2: GameplayPlayer = main.get_node("GameplayMSD/Player2")
	check(p1.sprite_override == null and p2.sprite_override == null, "default scenes leave Art overrides optional")
	check(p1.sprite.texture != p2.sprite.texture, "default P1 and P2 keep their distinct original mage sprites")
	main.queue_free()
	print("ART_HANDOFF_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
