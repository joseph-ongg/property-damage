## 来源：Ethan 46c3df2 / Jackson c897a2e。测试 Gameplay 适配器与远端公开契约。
## EN: Source: Ethan (Miao-Zinan), remote ethan/burn-box-grid, commit 46c3df2.
extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures.append(label)
		push_error("FAIL: "+label)
func frames(n: int) -> void:
	for _i in n: await physics_frame

func _run() -> void:
	var stage := Node2D.new()
	stage.name = "GridContract"
	root.add_child(stage)
	# 直接测试 Ethan 真正的 MaterialGrid，不再保留本地仿制数据仓库。
	# EN: Test Ethan's actual MaterialGrid instead of maintaining a local simulation copy.
	var grid := MaterialGrid.new()
	var timer := Timer.new()
	timer.name = "TickTimer"
	grid.add_child(timer)
	grid.name = "Grid"
	stage.add_child(grid)
	var bridge := GameplayFireBridge.new()
	bridge.name = "Bridge"
	stage.add_child(bridge)
	bridge.grid_path = NodePath("../Grid")
	var preview := GameplayMaterialGridPreview.new()
	preview.grid_path = NodePath("../Grid")
	preview.name = "Preview"
	stage.add_child(preview)
	await frames(3)
	var events: Array[Vector2i] = []
	bridge.cell_ignited.connect(func(cell: Vector2i): events.append(cell))
	var p := Vector2(43, 25)  # 第 (2,1) 格 / EN: Cell (2,1).
	check(bridge.world_to_cell(p) == Vector2i(2,1), "Ethan's world_to_cell mapping is honored")
	check(not bridge.ignite_world(p), "unpainted AIR is not falsely reported as ignited")
	check(events.is_empty(), "AIR ignition does not emit success event")
	grid.set_cell_material(2,1,MaterialGrid.Materials.STONE)
	check(not bridge.ignite_world(p), "STONE does not ignite")
	grid.set_cell_material(2,1,MaterialGrid.Materials.WOOD)
	check(bridge.ignite_world(p), "WOOD ignites via upstream void-returning API")
	check(bridge.is_burning_world(p), "bridge reads burning WOOD")
	check(events.size() == 1 and events[0] == Vector2i(2,1), "one genuine ignition emits one event")
	check(bridge.ignite_world(p) and events.size() == 1, "repeated ignite doesn't duplicate first-ignite event")
	grid.set_cell_material(2,1,MaterialGrid.Materials.WATER)
	check(not bridge.is_burning_world(p) and not bridge.ignite_world(p), "painting WATER extinguishes and rejects fire")
	grid.set_cell_material(2,1,MaterialGrid.Materials.OIL)
	check(bridge.ignite_world(p), "OIL ignition is supported")
	check(events.size() == 2, "new ignition after extinguishing triggers separate event")
	check(not bridge.ignite_world(Vector2(-50,-50)), "out-of-bounds does not ignite")
	check(preview.refresh_count >= 6, "Jackson-style viewer redraws from cell_changed events")
	stage.queue_free()
	print("UPSTREAM_GRID_SUMMARY failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
