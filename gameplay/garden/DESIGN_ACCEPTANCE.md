# PR #18 — Design acceptance matrix

Source: **[PUBLIC] DP Designs** ([Design document](https://docs.google.com/document/d/1iVnXhmA9XLGX5hUUSrxCrNm4u9ljC8tZb10seZF4FE8/edit)), rechecked 2026-11-18. Status labels are **Implemented**, **Provisional**, **Partial**, or **Owner handoff**. These distinctions matter: a passing headless test does not mean a complete playable match has been integrated.

| DP Designs requirement | Code / Art Team source | Status and reproducible check |
|---|---|---|
| Wizard: 120 HP, 1.0× movement, fireball | `gameplay/player.gd`, shared `gameplay/msd/magic_bolt.gd` | **Implemented.** Character + cross-arena projectile tests. |
| Ninja: 100 HP, 1.2× movement, higher jump, shuriken | Player stats; `ninja_jump_multiplier`; shared MagicBolt drawing | **Provisional.** Higher jump defaults to editable **1.10×**; temporary, visibly distinct shuriken now works in Living Room *and* Garden. Final numeric value and shuriken sprite require Design/Art sign-off. |
| Werewolf: 160 HP, 0.85× movement; “shoots cloth?” | Player stats / Art Team visual resources | **Partial.** Stats and art integrated; attack is a question in Design, so no invented mechanic. |
| All attacks start at 10 damage | `gameplay/garden/garden_magic_bolt.gd`, Eva Health | **Partial globally.** Both players do 10 HP in standalone Garden; existing Living Room attacks remain Gameplay/Austin-owned and are not reimplemented by PR #18. |
| Destroying an object grants a 5% damage multiplier | Garden fence `destroyed` signal and integer-HP fraction ledger | **Partial.** Confirmed for destroyed Garden fence segments. Tests verify 10+11 HP on two successful 10.5-HP shots and no bonus banked on Eva invulnerability. A universal item-destruction reward needs Austin/Eva integration. |
| Every item is flammable; burning removes 1 HP every 3 seconds, leaving ashes | `GardenMechanics` + `GardenThrowable` + upstream `MaterialGrid` | **Implemented for Garden props, provisional item HP.** Original Piskel fence fire footprint and Garden throwables burn/ash; 1 HP is a user-authorized placeholder where Design omits a Garden item durability. Austin's item fire system is reused when present. |
| Changed appearance / HP indicator as objects get damaged | Art Team sprite/fence visuals, HP HUD | **Partial.** Fence disappears after 4 hits, Garden items show ash, players have live HP. No per-hit intermediate fence deterioration graphic or individual item HP bars yet; ask Art/Gameplay. |
| Step in fire: 20 damage over 10 seconds; fire extinguishes itself after 10 seconds | Eva FireHazard attached to Garden / Ethan grid | **Partial.** Garden applies 2 HP per second through Eva Health. Fire propagation and automatic 10-second extinguishing are Simulation-owned and have **not** been signed off in an end-to-end test. |
| Throwing damage = object's pixel width × pixel height / 10,000 | Garden throwable 1-HP impact adapter | **Provisional divergence (explicit).** User approved **1 HP placeholder** for unspecified Garden values. Final Art pixel sizes and Austin's damage formula still require approval; do not claim the placeholder equals the Design formula. |
| Only `fragile` throwables break after a throw | Garden `fragile` tag | **Implemented.** Reusable objects survive a hit; fragile-tagged items are consumed, verified by Garden edge tests. |
| Fall damage after more than 2 character heights: (fall distance − 2× height)/10 | Conditional Eva-owned `fall_damage.gd` handoff | **Owner handoff.** Garden uses Eva's component only when available. Current `main` does not contain her latest fall class; formula stays Eva-owned, not duplicated. |
| Damageable object between attacker and player takes priority | `GameplayGardenMagicBolt` Piskel pixel-first ray test | **Implemented in Garden.** Physical player-before-item and visible-item-before-player tests pass. |
| Garden: eight independent fence segments, 4 HP each | Art Team `garden.piskel` exact alpha extraction; `GardenFenceSegment` | **Implemented.** Magic hits real opaque artwork, four hits destroy each of eight independent segments. |
| Garden tree holes transport players up and down | `GardenMechanics._try_tree_hole` | **Implemented.** Both directions and cooldown tested. |
| Bird occasionally leaves tree house and drops apples | Original Art Team bird frames, apple physics | **Provisional interval / art.** Editable 5-second interval; cap of six with safe recycling of unheld apples. Apple sprite is clearly temporary because the checked Art Team sources do not include a standalone apple. |
| Rose thorns deal 5 HP on contact | Garden rose areas / Eva Health | **Implemented.** Real Area2D contact test. |
| Throwable gnomes, mushrooms, apples, hose end | `GardenThrowable`, Garden original art parts | **Implemented as playable prototypes.** Original Piskel mushroom/nozzle pixels preserved; gnome and apple icons remain flagged temporary pending Art. |
| Hose sprays for 10 seconds, possibly 1 HP/s to enemy; extinguishes fire | Garden hose / upstream `MaterialGrid` | **Provisional damage.** 10-second spray, extinguish and throw/pickup are testable. The 1 HP/s PVP value is marked `(?)` in Design and can be disabled. |
| Two maps, character selection, rounds/winner/rematch | Angela's MapSelection and match controller; Garden's `player_defeated` + `prepare_new_round()` | **Owner handoff.** Garden handles its own playable round/death/reset, not the final two-map navigation, character selector or best-of-three scoring. A temporary Angela menu-path fix passes the integration-only two-round menu-to-Garden smoke test; current Angela PR still needs the real patch. |

## Original Art Team attribution

The Garden background, eight fence sections, mushrooms and nozzle are derived from the supplied original `garden.piskel` with pixel-for-pixel reconstruction; bird frames come from the Art Team's Bird drop animation Piskel. Ninja and Werewolf player frames are Art Team sources. Temporary **drawn** shuriken, apple and gnome indicators are **not** credited to Art Team. There is no Garden arena 3 or replacement game branding in PR #18.

## Verification

- `gameplay/garden/verify_pr18.sh --local`: initial Godot resource import and **24** focused headless tests, including both arenas' Ninja attack visuals.
- `gameplay/garden/verify_pr18.sh --branch-report`: current remote branch commit hashes and exact Git merge conflicts (non-mutating).
- `gameplay/garden/verify_pr18.sh --menu`: **integration-only** test using Angela's exact menu source with its Garden destination corrected in a disposable checkout; real button → scene transition → two projectile-based round wins → return to menu. **Does not** verify Angela's final best-of-three scoreboard.
- Full test evidence: `gameplay/garden/evidence/2026-11-18-original-art/qa_results.md` and `gameplay/garden/CROSS_BRANCH_COMPATIBILITY.md`.

## Required sign-off

Sandra / Design: Garden 1 HP placeholder, size-based damage, higher Ninja jump, hose PVP, bird interval, possible Werewolf attack. Art Team: gnome/apple/shuriken final frames and optional intermediate damage visuals. Angela: actual menu destination, character/map selection, match scoring and rematch. Austin/Eva: global items, HP and PvP synchronization. Ethan/Jackson: shared Simulation merge and fire lifetime.
