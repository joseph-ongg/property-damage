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
Design says Ninja jumps higher but gives no numerical multiplier; it is
**intentionally not guessed** in this limited-scope patch. Ninja's
shuriken, Werewolf's uncertain attack, final jump/action/death animations
and character-selection UI remain with their respective owners for
follow-up review. Sprites are sourced from Art Team's original Piskel
frames without synthetic animations or generated fallback sprites.
