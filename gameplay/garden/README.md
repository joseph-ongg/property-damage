# Garden artwork, not Garden mechanics

The Garden backdrop and three bird animation frames in
`gameplay/art_team/exported` are direct exports of Art Team Piskel
source files. Use `gameplay/garden/garden_art_preview.tscn` with F6
to preview them without replacing Angela's existing level selection.

The shared [Design specification](https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit)
explicitly describes Garden mechanics:
- eight fence segments with 4 HP each
- travel vertically through holes in the tree
- birds occasionally drop **apples**
- roses touching players deal 5 HP damage
- throwable hose end, gnomes, mushrooms and apples
- a *pick-up-able* hose shooting water for 10 seconds, 1 HP/s on contact (design marked tentative)

**This branch adds the source-accurate artwork only.** No experimental
gnome combat, stationary hose, generic bird damage, invulnerability
tree holes, third arena, global menus or invented rule changes are
included. Mechanics must be implemented separately with Design/Gameplay
approval and item-system ownership coordinated with Austin.
