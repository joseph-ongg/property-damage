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

The **shared** `GameplayMagicBolt` now draws a visibly distinct temporary
Ninja shuriken in **both Living Room and Garden**; the Wizard retains the
original hand-painted fireball. Garden's base PVP hit damage is Design's
**10 HP**, routed through Eva Health; Austin still owns Living Room's
shared item/player hit calculations. The shuriken glyph is **not Art Team
art** and its drawing change was tested against Austin's newer bolt
implementation without a merge conflict. Werewolf's exact attack is still
marked as a question in Design and is not fabricated. Final attack sheets,
action/death animations and Angela's character selection remain separate
owner handoffs. Idle/walk/hurt frames use the Art Team's original Piskel
exports.

See INTEGRATION_COMPATIBILITY.md for Eva/Austin integration contracts.
