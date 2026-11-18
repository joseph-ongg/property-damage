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

The Garden's Magic projectile draws a visibly distinct **temporary shuriken**
for Ninja, while Wizard uses the existing original fireball. Its base hit
damage is Design's **10 HP** against another player, through Eva Health.
This procedural shuriken is a clearly provisional visual, **not Art Team art**
(and not yet hooked to all arenas). Werewolf's exact attack is still marked
uncertain in Design and is not fabricated. Final attack sprite sheets,
action/death animations, and Angela's character-selection UI require separate
owner review. The idle/walk/hurt sprites use unmodified Art Team Piskel frames.

See INTEGRATION_COMPATIBILITY.md for Eva/Austin integration contracts.
