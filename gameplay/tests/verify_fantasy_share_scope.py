#!/usr/bin/env python3
"""Release gate: no Audio and no edits to Angela's selection implementation."""
from __future__ import annotations
import subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
BASE = "origin/suwen/full-game-integration-20261114"


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout


baseline = git("show", f"{BASE}:gameplay/MapSelection/map_select.gd")
current = (ROOT / "gameplay/MapSelection/map_select.gd").read_text()
assert baseline == current, "Angela's map/character selection script was modified"
assert (ROOT / "gameplay/presentation/lobby_decor.gd").exists(), "cosmetic lobby missing"
assert not (ROOT / "gameplay/presentation/audio").exists(), "audio directory present"
assert not (ROOT / "gameplay/presentation/sound_bus.gd").exists(), "SoundBus is present"
assert "[autoload]" not in (ROOT / "project.godot").read_text(), "autoload/AudioBus present"
changed = git("diff", "--cached", "--name-only", BASE).splitlines()
bad = [p for p in changed if (
    "/audio/" in p or "sound_bus" in p or
    p.endswith((".wav", ".ogg", ".mp3", ".flac", ".aac")) or
    p == "gameplay/MapSelection/map_select.gd"
)]
assert not bad, f"Excluded paths staged: {bad}"
source = (ROOT / "gameplay/presentation/generate_assets.py").read_text()
assert "wave.open" not in source and "sound" not in source.lower(), "generator still produces sound"
print(f"SHARE_SCOPE_OK changed_files={len(changed)} no_audio=true angela_script_unmodified=true")
