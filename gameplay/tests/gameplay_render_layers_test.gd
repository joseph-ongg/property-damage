## Verify that wall/furniture art stays behind the player, while interaction feedback stays above.
## 固定像素客厅的层级，避免冰箱内部与空调贴图盖住人物。
## Keep fridge interior and AC art behind both player sprites.
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
	var scene: Node2D = (load("res://gameplay/playtest_main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var room: Node2D = scene.get_node("GameplayMSD")
	var bg: CanvasItem = room.get_node("RoomVisuals")
	var furniture: CanvasItem = room.get_node("Appliances")
	var p1: CanvasItem = room.get_node("Player1")
	var p2: CanvasItem = room.get_node("Player2")
	var books: CanvasItem = room.get_node("Books")
	var spells: CanvasItem = room.get_node("Projectiles")
	var hints: CanvasItem = room.get_node("InteractionHints")
	var conditions: CanvasItem = room.get_node("PlayerConditions")
	check(bg.z_index < furniture.z_index, "room backdrop is behind appliance art")
	check(furniture.z_index < p1.z_index and furniture.z_index < p2.z_index, "fridge interior and AC stay behind both players")
	check(room.get_node("Appliances/FridgeDevice").z_index == 0 and room.get_node("Appliances/ACDevice").z_index == 0, "appliance draw functions inherit the lower parent layer")
	check(p1.z_index == p2.z_index, "both player sprites use the same layer")
	check(books.z_index > p1.z_index, "held books remain visible in front of the player")
	check(spells.z_index > p1.z_index, "ranged spell effects remain in front")
	check(hints.z_index > spells.z_index and conditions.z_index > spells.z_index, "interaction and SLOW overlays remain readable")
	check(scene.get_node("GameplayMSD/HUD") is CanvasLayer, "top HUD stays in an independent canvas layer")
	scene.queue_free()
	print("RENDER_LAYERS_SUMMARY failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
