"""Reproducibly export the Art & Audio team's original Piskel files.

Piskel sources in source/ are authoritative. The exported PNGs are generated
using Pillow without any image generation or hand-editing of source pixels.
"""
from __future__ import annotations

import base64
import hashlib
import io
import json
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "source"
OUTPUT = HERE / "exported"
SOURCES = {
    'Ninja_side.piskel': 'ninja_side',
    'Ninja_walk.piskel': 'ninja_walk',
    'Wolf walk.piskel': 'wolf_walk',
    'Wolf damage sprite.piskel': 'wolf_damage',
    'garden.piskel': 'garden',
    'Bird drop animation.piskel': 'bird_drop',
    # Original Art Team Drive handoff received Nov 21, 2026;
    # every frame/pixel is exported, no new art is drawn.
    'Ninja_fire.piskel': 'ninja_fire',
    'Ninja_injured.piskel': 'ninja_injured',
    'Ninja_dead.piskel': 'ninja_dead',
    'Wolf walking on fire.piskel': 'wolf_fire',
    'Tree.piskel': 'garden_tree_new',
    'Hose.piskel': 'garden_hose_full',
}


def _decode(value):
    return json.loads(value) if isinstance(value, str) else value


def frames_of(source: Path) -> tuple[list[Image.Image], int]:
    doc = json.loads(source.read_text(encoding="utf-8"))
    piskel = doc["piskel"]
    width, height = int(piskel["width"]), int(piskel["height"])
    fps = int(piskel.get("fps", 12))
    layers = [_decode(layer) for layer in piskel["layers"]]
    count = max(int(layer["frameCount"]) for layer in layers)
    frames = [Image.new("RGBA", (width, height)) for _ in range(count)]

    # Piskel stores topmost layers first; paint back to front. Each chunk
    # carries a tiled PNG and a 2D layout mapping tiles to frame indices.
    for layer in reversed(layers):
        opacity = float(layer.get("opacity", 1.0))
        for chunk in layer.get("chunks", []):
            data = chunk["base64PNG"].split(",", 1)[-1]
            with Image.open(io.BytesIO(base64.b64decode(data))) as im:
                sheet = im.convert("RGBA")
            layout = _decode(chunk["layout"])
            for col, indices in enumerate(layout):
                for row, idx in enumerate(indices):
                    if idx is None or int(idx) < 0 or int(idx) >= count:
                        continue
                    box = (col * width, row * height, (col + 1) * width, (row + 1) * height)
                    if box[2] > sheet.width or box[3] > sheet.height:
                        raise ValueError(f"Invalid Piskel chunk for {source.name}: {box}")
                    tile = sheet.crop(box)
                    if opacity < 1.0:
                        alpha = tile.getchannel("A").point(lambda a: int(a * opacity))
                        tile.putalpha(alpha)
                    frames[int(idx)].alpha_composite(tile)
    return frames, fps


def export() -> list[dict]:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = []
    for source_name, stem in SOURCES.items():
        src = SOURCE / source_name
        frames, fps = frames_of(src)
        outputs = []
        for i, frame in enumerate(frames):
            dest = OUTPUT / (f"{stem}.png" if stem in {"living_room_map", "garden"} else f"{stem}_{i}.png")
            frame.save(dest, optimize=True)
            outputs.append(dest.name)
        # "Hose.piskel" is one composite *fence + hose*. Never render the
        # permanent fence portion over eight breakable 4HP fence segments.
        # These pixel-exact regions are cropped from Art's original PNG:
        # x80..280 is ONLY the laid-out tube/tip; x260..280, y56..66 is
        # the authentic detachable tip, not a newly drawn replacement.
        derived_regions = {}
        if stem == "garden_hose_full":
            for output_name, xyxy in {
                "garden_hose_tube_latest.png": (80, 0, 280, 66),
                "garden_hose_tip_latest.png": (260, 56, 280, 66),
            }.items():
                frames[0].crop(xyxy).save(OUTPUT / output_name, optimize=True)
                derived_regions[output_name] = list(xyxy)
        manifest.append({
            "derived_regions": derived_regions,
            "original_name": source_name,
            "original_drive_url": "https://drive.google.com/drive/folders/1-bNX0VyVeyccPiMAJbUSJDj4b6Q0kjnJ",
            "source_sha256": hashlib.sha256(src.read_bytes()).hexdigest(),
            "frame_count": len(frames),
            "frame_size": list(frames[0].size),
            "fps": fps,
            "exports": outputs,
        })
    (HERE / "catalog.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return manifest


if __name__ == "__main__":
    for item in export():
        print(f"{item['original_name']}: {item['frame_count']} frames @ {item['fps']} fps -> {', '.join(item['exports'])}")
