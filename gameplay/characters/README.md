# Gameplay Characters

Character artwork for **Ninja** and **Werewolf** is in `sprites/`. Both have consistent 32×32 transparent canvases and animations for **Idle (2 frames), Run (4 frames), Jump (1), Attack (1), Hurt (1)**. The silhouettes and color language are designed alongside the two existing blue/red mage sprites while remaining visually distinct. Original images are produced deterministically using Pillow in `generate_characters.py`, with no image-generation tool or external artwork.

## Play

Open `res://gameplay/characters/character_demo.tscn` in Godot and run the scene (`F6`) to control P1 Ninja and P2 Werewolf on the existing arena. In this scene, press **1/2/3** to choose P1 Mage/Ninja/Werewolf or **7/8/9** to choose P2 Mage/Ninja/Werewolf while playing. Normal `gameplay/playtest_main.tscn` retains the existing blue/red Mage defaults. Run/Spark/Attack/Interact use the existing P1/P2 bindings and existing motor/physics.

## Integration

`GameplayPlayer.character_kind` accepts `mage`, `ninja` or `werewolf` and can be set in the Inspector or via `set_character_kind(kind)` for future selection UI. `character_art_override` accepts a `GameplayCharacterVisualSet` Resource and `sprite_override` still accepts a single legacy texture. `ninja_visuals.tres` and `werewolf_visuals.tres` group the frames independently of player input and collision. Assign new PNGs to the Resource to switch animations without changing the controller. Visual order is Hurt, Action, Jump, Run, Idle. The existing 32×64 CharacterBody collision shape, Layer 1 world and Layer 2 players, jumping, and P1/P2 input maps remain unchanged.

The Character Design document specifies Wizard speed ×1.0 / 120 HP / fireball; Ninja speed ×1.2 / 100 HP / shuriken / higher jump; Werewolf speed ×0.85 / 160 HP / attack projectile TBD. `character_design_info()` exposes these intended values, and the Ninja/Werewolf motor speed multipliers and Ninja jump multiplier are applied on character selection. **HP and projectile implementation are owned by their existing or future gameplay systems**: this integration does not replace Eva's `Health` component or Austin's attack logic. Sprite art displays the Ninja shuriken and Werewolf claw action. The Werewolf's projectile is pending Design confirmation. No new combat hitboxes or HP modifications are introduced.

### Art source and scale

All 32×32 source PNGs are authored by Suwen's Gameplay implementation using programmatic Pillow drawing (`generate_characters.py`) and can be regenerated. Existing Art Team mage PNG/GIF originals are preserved, not recolored or redistributed. Player sprite visual height remains 60px to align foot placement with the current arena; the physical collider is still 32×64. `sprite.flip_h` uses the existing facing and the same pixels for the opposite orientation.

## Real menu + Health integration (follow-up PR)

Angela's `gameplay/LevelSelection/map_select.tscn` now includes independent P1
(WASD) and P2 (arrow keys) character selectors above its existing Living
Room and Garden buttons. Pick Mage, Ninja, or Werewolf, then choose a map.
The **Living Room** loads real gameplay players with the selected character
kind, visual animations and movement/jump multipliers. The Garden scene is
still Angela's placeholder (no combatants to instantiate there yet).

The two chosen kinds travel across the scene change through the tiny
`character_selection_state.gd` session script (no project autoload or input
remapping). Only the existing team-room P1/P2 prefab instances opt into
using that state; standalone prefab demos and direct scene launches keep
explicit Inspector/default Mage choices. Return via the newly added
**Back to Maps (M)** button in the Living Room, or run `map_select.tscn`
directly, to select again. A fresh F5 run retains the original Mage defaults,
without changing `project.godot` or the team's default scene.

Every `GameplayPlayer` prefab now contains **Eva's original Health component**
and a compact numeric HP indicator (`HP current/max`) rather than an impractical
160-heart row. On character choice, the existing `Health.max_hp` and
`Health.reset()` are configured to **Mage 120, Ninja 100, Werewolf 160**.
Ninja / Werewolf movement multipliers and Ninja higher jump are unchanged.
`Health.changed` refreshes the indicator and `Health.damaged` shows the
existing Hurt art. Eva's `take_damage`, invulnerability, healing and death
signals are unmodified. Death/respawn and combat damage routing are not
implemented by this menu/HP integration.

**Austin's item/projectile gameplay remains separate:** Ninja shuriken and
Werewolf claws are action sprite poses, not newly invented hitboxes, item
physics, or damage values. Coordinate projectile and attack semantics with
Austin/Design before wiring real combat. The Werewolf projectile is still
TBD in the Design contract. The older draft character-art PR can merge first;
this integration can then be retargeted to `main` and re-reviewed.

Integration verification: `res://gameplay/tests/gameplay_character_selection_health_test.gd`
starts the actual Angela menu, chooses Ninja and Werewolf, navigates into the
Living Room, checks actual sprites, 32x64 colliders, motor parameters, Eva HP
and signals, hurt/heal/invulnerability, Back-to-Maps, reselects Mage and checks
a direct no-menu launch. Set `CAPTURE_CHARACTER_SELECT=/absolute/output/prefix`
and run Godot without `--headless` for real menu/game screenshots.
