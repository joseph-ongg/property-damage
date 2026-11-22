# Character art integration (Gameplay scope only)

The existing reusable `gameplay/prefabs/gameplay_player.tscn` exposes
`character_kind` (mage, ninja, werewolf) in the Inspector; gameplay code
or Angela's independently owned selection screen can call
`player.set_character_kind(kind)`. This PR **does not create a competing
map or character-selection UI**.

- Mage/Wizard: original prototype sprite, Design HP 120, move 1.0x
- Ninja: Art Team side/4-frame walk, Design HP 100, move 1.2x
- Werewolf: Art Team 2-frame walk and damage, Design HP 160, move 0.85x

All HP uses **Eva's existing Health.gd** component, which is not edited.
No new damage system or item mechanic is introduced.
Design requires a higher Ninja jump but does not specify the multiplier.
For playtesting, `GameplayPlayer.ninja_jump_multiplier` is Inspector-editable
and currently defaults to **1.10×**, explicitly **not Design-approved**.
Switching characters restores the original Mage/Werewolf jump speed without
stacking the Ninja bonus.

The **shared** GameplayMagicBolt distinguishes Wizard fireball, Ninja
shuriken and pending Werewolf attack in **both Living Room and Garden**.
Wizard retains original fireball frames. Art Team source does not include
a separate Ninja shuriken texture, and Design says only "Shoots cloth?"
for Werewolf (unapproved). Both unknown projectile visuals display small
colored "?" blocks rather than Wizard fireballs or invented attack art.
All characters keep the existing Design 10-HP base hit rules through Eva
Health. Original Art Team idle/walk/hurt stills mirror with facing direction
on every frame; the final attack assets/animation await Art and Design.


See INTEGRATION_COMPATIBILITY.md for Eva/Austin integration contracts.


## Nov 21 original Art left-facing alignment (PR #21)

Original Art Team Ninja side/run and Werewolf walk/hurt sprites
all face LEFT at flip_h=false, unlike Wizard's right-facing
original. The prior shared flip_h rule was therefore backwards
only for Ninja and Werewolf. PR #21 now mirrors their existing
Sprite2D when moving RIGHT, not LEFT; it updates idle/run/hurt,
both players, live keyboard turns, and Garden round reset.
No PNG or Piskel source artwork has been rewritten.

The Nov 21 Art Drive newly contains Ninja_fire (four frames),
Ninja_injured (four), Ninja_dead (one), and separated Hose
Piskel. Their ownership and unresolved animation use are in
gameplay/integration/two_map_playtest/DRIVE_ART_DESIGN_RECHECK_2026-11-21.md.
A new Ninja flame pose is not permission to replace the
Design-approved shuriken projectile with a fireball.
