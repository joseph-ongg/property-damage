# Burn Box: Sim & Systems Onboarding

**Team:** Jackson, Ethan, Bryan
**Repo path:** `onboarding/burn-box/`
**Due:** working build merged by Sun, Oct 11; demoed live at MSD on Thu, Oct 15

## What you're building

A playable fire-spreading sandbox. Single screen, no fighters, no win condition: just a grid of materials that burns in satisfying ways. Art will drop in textures and Design will tune the numbers. Your job is to make the engine clean enough that they can do both from the Inspector without editing your scripts.

Burn Box uses the same grid API and tile order as the Property Damage onboarding doc, so this becomes the real sim, not a throwaway.

## Features to ship

**Fire spread**: each tick, every burning cell tries to ignite each flammable 4-neighbor, using that neighbor's spread chance (wood and oil differ). A cell burns for its material's burn time, then becomes ash. Randomness plus different chances per material is what makes it feel alive instead of mechanical.

**Materials**: Air, Wood, Stone, Oil, Ash, Water.

| Material | Flammable | Rule |
| --- | --- | --- |
| Air | No | Nothing |
| Wood | Yes | Spreads at `wood_spread_chance`, burns `wood_burn_ticks` |
| Stone | No | Blocks fire |
| Oil | Yes | Spreads at `oil_spread_chance`, burns `oil_burn_ticks` (fast and hot) |
| Ash | No | What burnt cells become |
| Water | No | Any burning cell next to water goes out (stays its material, stops burning). Water doesn't move. |

**Paintbrush**: a material selector in the HUD with Air, Wood, Stone, Oil, Water, and **Fire**. Left click (and drag) paints the selected material; with Fire selected, left click ignites instead. Right click paints stone. Clicks on the HUD must not paint.

**Tunable knobs**: spread chances, burn times, and tick rate are `@export` vars, grouped under "Tuning" in the Inspector.

**Default map**: a hand-built starting layout (wood buildings, stone walls, oil patches, water) that shows off every material. You light the first fire live at MSD.

## Who owns what

One owner per file, one branch and one PR per person, each reviewed by someone else. Swap owners at your first sync if you want, but keep one owner per file so you never merge-conflict on the same script.

| Owner | Files | Branch | Ships |
| --- | --- | --- | --- |
| Ethan | `material_grid.gd` (the `_on_tick` rules only) | `sim/burn-box-rules` | Spread, burnout to ash, water rule |
| Jackson | `grid_renderer.gd`, `default_map.gd` | `sim/burn-box-render` | Colors per material, burning tint, the default map |
| Bryan | `paintbrush.gd`, HUD in `burn_box.tscn` | `sim/burn-box-brush` | Material selector, painting, fire brush |

You still have to talk: Jackson can't show off the map until Ethan's fire spreads, and Bryan's Fire brush is the easiest way for Ethan to test spread. Everyone can work in parallel from day one because the API below already exists as a stub.

## Starter code

PMs merge this to `main` before you start. Open `burn_box.tscn` and press F6 to run it (Godot 4.7.2, per setup.md).

**Scene tree** (`burn_box.tscn`):
```
BurnBox (Node2D) · material_grid.gd
├── TickTimer (Timer)
├── Renderer (Node2D) · grid_renderer.gd
├── Paintbrush (Node) · paintbrush.gd
└── UI (CanvasLayer)
    └── HUD (VBoxContainer)
        └── MaterialPicker (OptionButton)
```

**`material_grid.gd`**: the sim. Everything except `_on_tick` is done; Ethan fills in the rules.
```gdscript
# onboarding/burn-box/material_grid.gd
class_name MaterialGrid
extends Node2D

signal cell_changed(x: int, y: int, material: int)  # fired by set_cell and ignite
signal ticked                                        # fired after every sim step

# Order matches the tile index table in the onboarding doc. Add new materials at the end.
enum Cell { AIR, WOOD, STONE, OIL, ASH, WATER }

@export var width := 64
@export var height := 36
@export var cell_size := 16

@export_group("Tuning")
@export var wood_spread_chance := 0.3
@export var oil_spread_chance := 0.7
@export var wood_burn_ticks := 12
@export var oil_burn_ticks := 6
@export var tick_rate := 0.1:
    set(value):
        tick_rate = value
        if is_node_ready():
            $TickTimer.wait_time = value

var grid: Array = []      # grid[x][y] -> Cell. Burning cells keep their material.
var burn_age: Array = []  # burn_age[x][y] -> 0 if not burning, else ticks spent burning

func _ready() -> void:
    for x in width:
        grid.append([])
        burn_age.append([])
        for y in height:
            grid[x].append(Cell.AIR)
            burn_age[x].append(0)
    DefaultMap.fill(self)
    $TickTimer.wait_time = tick_rate
    $TickTimer.timeout.connect(_on_tick)
    $TickTimer.start()

func _on_tick() -> void:
    var next_grid := grid.duplicate(true)
    var next_age := burn_age.duplicate(true)
    for x in width:
        for y in height:
            pass  # TODO (Ethan): read from grid/burn_age, write only to next_grid/next_age.
                  # 1. Burning cell next to water -> goes out.
                  # 2. Burning cell -> try to ignite each flammable neighbor (randf() < spread_chance(neighbor)).
                  # 3. Burning cell -> age += 1; at burn_ticks(material), becomes ASH and stops burning.
    grid = next_grid
    burn_age = next_age
    ticked.emit()

# ---------- Public API: Gameplay, Design, and the rest of this team call these ----------

func in_bounds(x: int, y: int) -> bool:
    return x >= 0 and x < width and y >= 0 and y < height

func get_cell(x: int, y: int) -> int:
    return grid[x][y]

func set_cell(x: int, y: int, material: int) -> void:
    if not in_bounds(x, y):
        return
    grid[x][y] = material
    burn_age[x][y] = 0
    cell_changed.emit(x, y, material)

func is_burning(x: int, y: int) -> bool:
    return burn_age[x][y] > 0

func ignite(x: int, y: int) -> void:
    if in_bounds(x, y) and is_flammable(grid[x][y]) and not is_burning(x, y):
        burn_age[x][y] = 1
        cell_changed.emit(x, y, grid[x][y])

func is_flammable(material: int) -> bool:
    return material == Cell.WOOD or material == Cell.OIL

func spread_chance(material: int) -> float:
    match material:
        Cell.WOOD: return wood_spread_chance
        Cell.OIL: return oil_spread_chance
    return 0.0

func burn_ticks(material: int) -> int:
    match material:
        Cell.WOOD: return wood_burn_ticks
        Cell.OIL: return oil_burn_ticks
    return 0

func world_to_cell(world_pos: Vector2) -> Vector2i:
    var local := to_local(world_pos)
    return Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))

func neighbors(x: int, y: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        var nx := x + offset.x
        var ny := y + offset.y
        if in_bounds(nx, ny):
            result.append(Vector2i(nx, ny))
    return result
```

**`grid_renderer.gd`**: draws the grid. Art fills in `textures` from the Inspector; anything without a texture falls back to its color.
```gdscript
# onboarding/burn-box/grid_renderer.gd
extends Node2D

@onready var grid: MaterialGrid = get_parent()

@export var colors: Dictionary = {
    MaterialGrid.Cell.AIR: Color(0.08, 0.08, 0.1),
    MaterialGrid.Cell.WOOD: Color.DARK_GRAY,    # TODO (Jackson): real colors
    MaterialGrid.Cell.STONE: Color.DARK_GRAY,
    MaterialGrid.Cell.OIL: Color.DARK_GRAY,
    MaterialGrid.Cell.ASH: Color.DARK_GRAY,
    MaterialGrid.Cell.WATER: Color.DARK_GRAY,
}
@export var textures: Dictionary = {}  # Cell -> Texture2D. Art's handoff point.
@export var burning_tint := Color(1.0, 0.45, 0.1, 0.6)

func _ready() -> void:
    grid.ticked.connect(queue_redraw)
    grid.cell_changed.connect(func(_x, _y, _m): queue_redraw())

func _draw() -> void:
    var s := grid.cell_size
    for x in grid.width:
        for y in grid.height:
            var m := grid.get_cell(x, y)
            var rect := Rect2(x * s, y * s, s, s)
            if textures.has(m):
                draw_texture_rect(textures[m], rect, false)
            else:
                draw_rect(rect, colors.get(m, Color.MAGENTA))
            if grid.is_burning(x, y):
                draw_rect(rect, burning_tint)  # TODO (Jackson): flicker it, if you have time
```

**`default_map.gd`**: the MSD layout.
```gdscript
# onboarding/burn-box/default_map.gd
class_name DefaultMap

static func fill(grid: MaterialGrid) -> void:
    pass  # TODO (Jackson): wood buildings, stone walls, oil patches, water.
          # Use grid.set_cell(x, y, MaterialGrid.Cell.WOOD) and friends.
```

**`paintbrush.gd`**: input.
```gdscript
# onboarding/burn-box/paintbrush.gd
extends Node

const FIRE_BRUSH := -1

@onready var grid: MaterialGrid = get_parent()
var brush: int = MaterialGrid.Cell.WOOD  # a Cell value, or FIRE_BRUSH

func _unhandled_input(event: InputEvent) -> void:
    pass  # TODO (Bryan): _unhandled_input means clicks on the HUD never reach here.
          # Mouse position: grid.world_to_cell(grid.get_global_mouse_position()).
          # Left click/drag: set_cell(brush), or ignite() if brush == FIRE_BRUSH.
          # Right click/drag: set_cell(STONE).
          # Hook MaterialPicker's item_selected signal up to change `brush`.
```

## Stretch goals

Only after the Oct 4 meeting shows fire spreading:

- Wind direction biasing spread
- Oil and water flow down like falling sand
- Oil pool explosion
- Temperature diffusion

## Handoff contract

When you're done, the next teams get:

- **Art** sets `textures` on the Renderer node in the Inspector. No script edits.
- **Design** tunes everything under "Tuning" on BurnBox in the Inspector. No script edits.
- **Gameplay** calls `ignite`, `is_burning`, `get_cell`, `set_cell`, `world_to_cell`, and `neighbors`, and can listen to `cell_changed` and `ticked`. These names match the onboarding doc's MaterialGrid API.
- New materials go at the end of the `Cell` enum so tile indices never shift.
