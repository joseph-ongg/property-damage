# Burn Box: Sim & Systems Onboarding

**Team:** Ethan, Jackson, Bryan
**Repo path:** `onboarding/burn-box/`
**Due:** interface ideally by Sun, Oct 4; working build merged by MSD; handed to the other teams at the Sun, Oct 4 meeting; demoed live at MSD on Thu, Oct 15

## What you're building

A playable fire-spreading sandbox. Single screen, no fighters, no win condition: just a grid of materials that burns in satisfying ways.

Burn Box is the core of Property Damage. After Oct 4, Gameplay, Design, and Art build their parts directly on top of it, so the most important thing you make isn't the fire. It's the interface everyone else calls.

## What's already done

The tedious plumbing is set up so you can start on the interesting part. Open `burn_box.tscn` and press F6: it runs with no errors and shows an empty grid.

- `burn_box.tscn`: the scene tree below, with the tick timer and HUD wired up
- `material_grid.gd`: grid size, a 10 Hz tick loop, an Inspector "Tuning" group, and helpers (`in_bounds`, `world_to_cell`, `neighbors`)
- `grid_renderer.gd`: a loop that draws every cell as a dark square
- `paintbrush.gd`: turns mouse clicks into a grid cell, and ignores clicks on the HUD
- `default_map.gd`: an empty `fill()` for the starting layout

```
BurnBox (Node2D) · material_grid.gd
├── TickTimer (Timer)
├── Renderer (Node2D) · grid_renderer.gd
├── Paintbrush (Node) · paintbrush.gd
└── UI (CanvasLayer)
    └── HUD (VBoxContainer)
        └── MaterialPicker (OptionButton)
```

None of it is sacred. Change or replace anything if you have a better idea.

## Step 1: Design the interface (by Sun, Oct 4)

Before you write the fire, decide how the rest of the game will talk to your grid. Write the interface as real code: in the "Public API" section of `material_grid.gd`, add every public function and signal with its final name, typed arguments, return type, and a one-line comment on what it's for. Leave the body as `pass` (or return a placeholder value) for now:

```gdscript
## Sets the cell at (x, y) on fire, if its material can burn.
func ignite(x: int, y: int) -> void:
	pass
```

That section is your design doc. Open it as a PR on `sim/burn-box-interface` and tag a PM for sign-off. Because it's real code, it can't drift out of date, and other teams can start calling your functions the moment it merges.

Other teams will need to do these things. Your interface has to make all of them possible:

- **Gameplay** needs to set a specific cell on fire (a player drops a spark), ask whether a cell is burning (so standing in fire hurts), and ask what material a cell is (so players can stand on it).
- **Gameplay** also needs to know when cells change, without checking every cell every frame.
- **Design** needs to paint materials into a map, and tune spread and burn numbers from the Inspector without editing your scripts.
- **Art** needs to swap the colored squares for real textures without editing your simulation code.

Questions worth arguing about as a team:

- How do you store a cell? Just a material, or a material plus separate state like "burning" and "how long it's burned"? (Watch out: if a cell becomes `BURNING`, do you still know if it was wood or oil?)
- Who is allowed to change a cell directly, and who has to go through a function?
- What signals does the grid send, and how often?
- How do you add a new material in week 5 without breaking everyone else's code?

Once that PR merges, the function names are frozen. You can change what's inside them any time, but renaming or changing their inputs needs a PM's OK, because other teams will be calling them.

## Step 2: Build it (by MSD)

**Fire spread**: fire spreads to flammable neighbors with some randomness each tick, and cells eventually burn out to ash. It should feel alive, not mechanical.

**Materials**: at least Air, Wood, Stone, Oil, Ash, and Water, each behaving differently. You decide the rules. At minimum, Stone blocks fire, Oil burns faster than Wood, and Water puts out fire next to it.

**Paintbrush**: the dropdown lists every material plus Fire. Left click (and drag) paints the selected material, or ignites with Fire selected. Right click paints stone.

**Tunable knobs**: spread chances, burn times, and anything else worth tweaking are `@export` vars under "Tuning", so Design can change them in the Inspector.

**Default map**: a hand-built layout (wood buildings, stone walls, oil patches, water) that shows off every material. You light the first fire live at MSD.

## Who owns what

One owner per file, one branch and one PR per person, each reviewed by someone else. Swap owners at your first sync if you want, but keep one owner per file so you never merge-conflict on the same script.

| Owner | Files | Branch | Ships |
| --- | --- | --- | --- |
| Ethan | `material_grid.gd` | `ethan/burn-box-grid` | Cell storage, public API, fire rules |
| Jackson | `grid_renderer.gd`, `default_map.gd` | `jackson/burn-box-render` | Drawing each material, burning look, the default map |
| Bryan | `paintbrush.gd`, HUD in `burn_box.tscn` | `bryan/burn-box-brush` | Material picker, painting, fire brush |

Step 1 is a whole-team job, not Ethan's alone. Everyone's file depends on the interface, so all three of you should agree on it and all three should review the PR.

## Rules

- GDScript only, no C#. Keep the public functions readable; beginners on other teams will read them to learn how to use the grid. If you optimize later, hide it behind the same function names and leave a comment saying why.
- Keep the grid at 64 x 36 and 10 Hz until it's working. Profile before making it bigger or faster.

## Stretch goals (after MSD)

Once the other teams have taken over the basics, these become your real work, since they're what Property Damage's arena needs:

- Oil and water flow down like falling sand
- Structural collapse
- Wind direction biasing spread
- Oil pool explosions

From Oct 4 to Oct 11, each of you is also the go-to person for one other team's questions about the grid.
