"""Deterministic, original 48x56 pixel desk fan (no external/image AI assets).

Three aligned, independently replaceable RGBA planes: rear housing and base,
six rotor poses, near cage. A diagonally leaning oval and offset rear shell
make the head look slightly turned/tilted toward the left, with a legible
three-quarter silhouette even at 1x. Keep existing gameplay registration.
"""
from pathlib import Path
from math import cos, radians, sin
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent / "sprites"
ROOT.mkdir(parents=True, exist_ok=True)
W, H = 48, 56
# Matches the game's steel-blue, aged brass and wood-brown pixel palette.
INK = "#273747"
INK_DEEP = "#1b2939"
STEEL_DARK = "#436271"
STEEL_MID = "#7d9fa9"
STEEL_LIGHT = "#bdcfc8"
BONE = "#ece1be"
BRASS = "#dbb580"
RUST = "#8b655b"
WOOD = "#af8270"
BLADE = "#81bec5"
BLADE_LIGHT = "#b8d9d5"


def make():
    image = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def poly(draw, pts, fill):
    draw.polygon([(int(round(x)), int(round(y))) for x, y in pts], fill=fill)


def ellipse(draw, cx, cy, rx, ry, **kw):
    draw.ellipse((cx-rx, cy-ry, cx+rx, cy+ry), **kw)


# Rear plane: heavy fan body sits BEHIND the front oval with 6-8px parallax.
rear, draw = make()
ellipse(draw, 25, 51, 17, 3, fill=(15, 26, 38, 95))
# Grounded foot with dark bottom, warm top, two exposed side facets.
poly(draw, [(10, 49), (14, 46), (31, 46), (37, 50), (34, 53), (11, 53)], INK_DEEP)
poly(draw, [(12, 48), (16, 46), (30, 46), (34, 49), (14, 49)], RUST)
draw.line([(14, 47), (29, 47)], fill=BRASS, width=1)
draw.line([(13, 51), (33, 51)], fill=WOOD, width=1)
draw.rectangle((17, 49, 32, 49), fill="#634a4b")
# Diagonal stalk tilts the head LEFT, while the foot stays horizontal.
poly(draw, [(24, 47), (29, 47), (28, 32), (25, 29), (22, 32)], INK)
poly(draw, [(25, 46), (27, 46), (26, 34), (24, 31), (23, 33)], STEEL_MID)
draw.line([(25, 40), (25, 45)], fill=STEEL_LIGHT)
# Tilt bearing and exposed warm pivot dot.
poly(draw, [(20, 32), (23, 29), (29, 30), (31, 33), (28, 36), (23, 35)], INK_DEEP)
poly(draw, [(22, 32), (26, 30), (29, 32), (27, 34), (23, 34)], STEEL_MID)
draw.point((25, 33), fill=BRASS)
# Rear motor assembly; the body extends right, behind the front grille.
poly(draw, [(19, 8), (26, 7), (31, 10), (35, 15), (36, 20),
            (36, 25), (33, 30), (28, 33), (20, 33), (16, 28),
            (16, 13)], INK_DEEP)
poly(draw, [(21, 10), (27, 9), (31, 12), (33, 17), (34, 23),
            (31, 28), (27, 31), (22, 30), (19, 25), (19, 15)], STEEL_DARK)
poly(draw, [(27, 10), (29, 12), (32, 17), (33, 23), (31, 27),
            (28, 30), (30, 24), (30, 17)], STEEL_MID)
draw.line([(30, 13), (32, 18), (32, 23)], fill=STEEL_LIGHT, width=1)
# Tail vent slots and inset side highlight distinguish the motor from grille.
for y in (17, 21, 25):
    draw.line([(33, y), (34, y+1)], fill=INK_DEEP, width=1)
# Recessed oval behind blades. Tilt the front plane left at its top.
poly(draw, [(14, 6), (20, 7), (25, 12), (27, 18), (28, 24),
            (24, 30), (20, 33), (14, 32), (9, 28), (7, 22),
            (8, 14), (10, 9)], INK_DEEP)
poly(draw, [(14, 9), (20, 10), (23, 15), (24, 22),
            (22, 27), (19, 30), (13, 29), (10, 24),
            (10, 16)], STEEL_DARK)
rear.save(ROOT / "rear.png", optimize=True)

# Left-tilted oval center is near (17, 20), while the motor is near x30.
# Blade shape is a tapered swept wedge; each frame rotates 20 degrees.
for frame in range(6):
    blade, draw = make()
    phase = frame * 20.0 + 15
    for arm in range(3):
        a = radians(phase + 120 * arm)
        dx, dy = cos(a), sin(a)
        nx, ny = -dy, dx
        vertices = [(17 + dx*1.2 + nx*0.7, 20 + dy*1.2 + ny*0.7),
                    (17 + dx*6.5 + nx*2.8, 20 + dy*9.2 + ny*1.6),
                    (17 + dx*7.4 - nx*0.8, 20 + dy*10.8 - ny*0.6),
                    (17 + dx*2.4 - nx*1.7, 20 + dy*3.2 - ny*1.5)]
        poly(draw, vertices, BLADE)
        draw.line([tuple(map(round, vertices[0])),
                   tuple(map(round, vertices[1]))], fill=BLADE_LIGHT, width=2)
    blade.save(ROOT / f"blade_{frame}.png", optimize=True)

front, draw = make()
# Tilted, hand-pixelated outer 12-point silhouette, rather than a perfect
# vertical ellipse. The left highlight and right occlusion give true depth.
outer = [(13, 5), (20, 6), (25, 10), (28, 16), (29, 23),
         (26, 29), (21, 34), (15, 34), (9, 31), (6, 26),
         (5, 19), (7, 12)]
inner = [(14, 8), (19, 9), (23, 13), (25, 18), (26, 23),
         (23, 28), (19, 31), (15, 31), (11, 28), (9, 24),
         (8, 19), (10, 13)]
# Pixelated 2px silhouette edge; inner transparent so blades read through.
path = outer + [outer[0]]
draw.line(path, fill=INK_DEEP, width=3, joint="curve")
draw.line(inner + [inner[0]], fill=STEEL_LIGHT, width=1)
# Three fine spokes and one partial inner ring leave the rotor visible.
# The front cage is still physically on top of the blades, not flattened.
for xx, yy in [(16, 9), (25, 22), (12, 28)]:
    draw.line([(17, 20), (xx, yy)], fill=(210, 228, 222, 115), width=1)
draw.arc((11, 10, 24, 30), 65, 242, fill=(178, 207, 208, 104), width=1)
draw.line([(8, 12), (6, 18), (7, 24), (10, 29)], fill=BONE, width=2)
draw.point((7, 16), fill="#fff3d5")
draw.point((9, 27), fill="#fff3d5")
draw.line([(26, 13), (28, 19), (28, 24), (25, 29)], fill=STEEL_DARK, width=2)
# Small central brass hub with a clear dark outline.
ellipse(draw, 17, 20, 3, 3, fill=INK_DEEP)
ellipse(draw, 17, 20, 2, 2, fill=BRASS)
draw.point((16, 19), fill=BONE)
front.save(ROOT / "front.png", optimize=True)

sheet = Image.new("RGBA", (W * 6, H))
for frame in range(6):
    combined = rear.copy()
    combined.alpha_composite(Image.open(ROOT / f"blade_{frame}.png"))
    combined.alpha_composite(front)
    sheet.alpha_composite(combined, (frame * W, 0))
sheet.save(ROOT / "preview_sheet.png", optimize=True)
print("Generated angled 48x56 pixel fan, three layers, six animation frames")
