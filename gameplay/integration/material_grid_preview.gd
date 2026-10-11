## 来源：Jackson，origin/sim/jackson/burn-box-render @ c897a2e。
## Source: Jackson, sim/jackson/burn-box-render, commit c897a2e.
## 功能：参考他的 MaterialGrid 颜色映射与 cell_changed 驱动的重绘。
## Reuse the MaterialGrid color palette and cell_changed-based redraw approach.
## 这是可选调试预览；默认场景不要叠加，否则会遮住像素客厅。
## Optional debug overlay; do not cover the default pixel-art living room.
## 不复制 Jackson 的渲染器到 Simulation；此脚本仅渲染 API 状态，不做燃烧计算。
## Do not duplicate Jackson's Simulation renderer; only display API states here.
class_name GameplayMaterialGridPreview
extends Node2D

@export_node_path("Node2D") var grid_path: NodePath
@export var show_air: bool = false
@export var opacity: float = 0.55

var _grid: Node2D = null
var refresh_count: int = 0

const MATERIAL_COLORS: Array[Color] = [
	Color("8c98b2"),  # AIR（默认透明） / AIR is transparent by default.
	Color("906344"),  # WOOD
	Color("777c85"),  # STONE
	Color("302f3a"),  # OIL
	Color("494c54"),  # ASH
	Color("4b93bc")   # WATER
]

func _ready() -> void:
	_grid = get_node_or_null(grid_path) as Node2D
	if _grid != null and _grid.has_signal("cell_changed"):
		_grid.connect("cell_changed", _on_cell_changed)
	queue_redraw()

func _on_cell_changed(_x: int, _y: int) -> void:
	# 材料变化时才请求重绘，避免每帧遍历整张地图。
	# Request a redraw only after material changes, not every frame.
	refresh_count += 1
	queue_redraw()

func _draw() -> void:
	if _grid == null or not _grid.has_method("get_cell_material") or not _grid.has_method("is_burning"):
		return
	var cell_size: int = _grid.get("cell_size")
	var width: int = _grid.get("width")
	var height: int = _grid.get("height")
	for x in width:
		for y in height:
			var material: int = int(_grid.call("get_cell_material", x, y))
			if material == 0 and not show_air:
				continue
			var color: Color = MATERIAL_COLORS[clampi(material, 0, MATERIAL_COLORS.size() - 1)]
			if bool(_grid.call("is_burning", x, y)):
				color = Color("ff833f")
			color.a *= opacity
			draw_rect(Rect2(x*cell_size, y*cell_size, cell_size, cell_size), color)
