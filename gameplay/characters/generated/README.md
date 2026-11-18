# Temporary missing-action overlays (Gameplay integration)

The Art & Audio team's original Piskel Ninja and Wolf idle/walk/hurt
animation frames remain the authoritative base, unchanged at
`gameplay/art_team/source/`.

We generated small additional **temporary** 32×32 action/jump/hurt poses
by layering original programmatic mint/gold/pink effects on top of those
original character pixels. This is strictly Gameplay placeholder work
to fill missing production animations; it is not attributed as official
Art & Audio delivery.

Regenerate without generative tools:

```bash
/usr/bin/python3 gameplay/characters/generate_temporary_poses.py
```

- Ninja: jump/action/hurt
- Werewolf: jump/action, plus an unused optional tinted hurt overlay
- Wolf's original Art Team `wolf_damage_1.png` remains the official live
  hurt resource.

The temporary resource paths are in
`gameplay/characters/ninja_visuals.tres` and
`gameplay/characters/werewolf_visuals.tres`, so Art can replace them
without editing any player physics or code.
