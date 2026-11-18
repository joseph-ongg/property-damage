extends Node2D

@export_node_path("Node") var furniture_layer_path: NodePath = NodePath("../MaterialGrid/FurnitureFireLayer")
@export var fade_time: float = 0.4

var _layer: GameplayFurnitureFireLayer
var _grid: MaterialGrid
var _ages: Dictionary = {}   # grid object id -> seconds since destroyed
var _piles: Array[Dictionary] = []  # off-grid appliances: {"rect": Rect2, "age": float}


func _ready() -> void:
	_layer = get_node_or_null(furniture_layer_path) as GameplayFurnitureFireLayer
	if _layer != null:
		_grid = _layer.get_parent() as MaterialGrid
		_layer.object_destroyed.connect(func(id: String): _ages[id] = 0.0; queue_redraw())
	var appliances := get_node_or_null("../Appliances")
	if appliances != null:
		for child in appliances.get_children():
			var a := child as GameplayAppliance
			if a != null and a.device in [GameplayAppliance.Device.FAN, GameplayAppliance.Device.COMPUTER]:
				a.vanished.connect(_on_appliance_vanished.bind(a))


func _on_appliance_vanished(_device: int, a: GameplayAppliance) -> void:
	var local := GameplayAppliance.FAN_RECT if a.device == GameplayAppliance.Device.FAN \
		else GameplayAppliance.MONITOR_RENDER_RECT
	_piles.append({"rect": Rect2(a.global_position + local.position, local.size), "age": 0.0})
	queue_redraw()


func _process(delta: float) -> void:
	var changed := false
	for id: String in _ages:
		if _ages[id] < fade_time:
			_ages[id] += delta
			changed = true
	for pile in _piles:
		if pile.age < fade_time:
			pile.age += delta
			changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	if _grid != null:
		_draw_cell_ash()
	for pile in _piles:
		_draw_mound(pile.rect, clampf(pile.age / fade_time, 0.0, 1.0))


func _draw_cell_ash() -> void:
	var side := float(_grid.cell_size)
	for id: String in _ages:
		var alpha := clampf(_ages[id] / fade_time, 0.0, 1.0)
		for cell: Vector2i in _layer.object_cells(id):
			var h := (cell.x * 73856093) ^ (cell.y * 19349663)
			var shade := 0.16 + float(posmod(h, 5)) * 0.03
			var top_left := Vector2(cell) * side
			draw_rect(Rect2(top_left, Vector2(side, side)), Color(shade, shade, shade + 0.02, alpha))
			if posmod(h >> 3, 3) == 0:
				draw_rect(Rect2(top_left + Vector2(3, 4), Vector2(3, 2)), Color(0.45, 0.43, 0.42, alpha))
			if posmod(h >> 5, 4) == 0:
				draw_rect(Rect2(top_left + Vector2(9, 10), Vector2(2, 2)), Color(0.55, 0.52, 0.5, alpha))


func _draw_mound(rect: Rect2, alpha: float) -> void:
	var cx := rect.position.x + rect.size.x * 0.5
	var base := rect.end.y
	for i in 3:  # three stacked strips, narrowing upward
		var w := rect.size.x * (0.8 - float(i) * 0.24)
		var shade := 0.20 + float(i) * 0.07
		draw_rect(Rect2(Vector2(cx - w * 0.5, base - 5.0 * float(i + 1)).round(), Vector2(w, 5)),
			Color(shade, shade, shade + 0.02, alpha))
