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
