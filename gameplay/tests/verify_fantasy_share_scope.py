#!/usr/bin/env python3
"""Release gate: exact Angela 55fe753 map code, no audio, both ancestries."""
from __future__ import annotations
import subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
BASE = "55fe7533e8549783517b30619b06567333e09d24"


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout


baseline = git("show", f"{BASE}:gameplay/MapSelection/map_select.gd")
current = (ROOT / "gameplay/MapSelection/map_select.gd").read_text()
assert baseline == current, "Angela's original 55fe753 map selection logic was modified"
assert (ROOT / "gameplay/presentation/lobby_decor.gd").exists(), "cosmetic lobby missing"
assert not (ROOT / "gameplay/presentation/audio").exists(), "audio directory present"
assert not (ROOT / "gameplay/presentation/sound_bus.gd").exists(), "SoundBus is present"
assert "[autoload]" not in (ROOT / "project.godot").read_text(), "autoload/AudioBus present"
changed = set(git("diff", "--name-only", BASE, "HEAD").splitlines())
changed.update(git("diff", "--cached", "--name-only", BASE).splitlines())
bad = [p for p in changed if (
    "/audio/" in p or "sound_bus" in p or
    p.endswith((".wav", ".ogg", ".mp3", ".flac", ".aac")) or
    p == "gameplay/MapSelection/map_select.gd"
)]
assert not bad, f"Excluded paths staged: {bad}"
assert git("merge-base", "--is-ancestor", BASE, "HEAD") == "", "Angela is not an ancestor"
assert git("merge-base", "--is-ancestor", "5e4ce8d", "HEAD") == "", "Gameplay history was lost"
source = (ROOT / "gameplay/presentation/generate_assets.py").read_text()
assert "wave.open" not in source and "sound" not in source.lower(), "generator still produces sound"
print(f"SHARE_SCOPE_OK changed_files={len(changed)} no_audio=true angela_script_unmodified=true")
