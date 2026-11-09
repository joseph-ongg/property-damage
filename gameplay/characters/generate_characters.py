"""Original 32x32 Ninja and Werewolf pixel art for Property Damage.

Drawn entirely with Pillow polygons and rectangles, no AI image tool and no
third-party art. Existing Art Team mages inform outline/palette proportions
only; none of their pixels are copied into these sprites.
"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent / "sprites"
OUT.mkdir(exist_ok=True, parents=True)
SZ = 32
INK = '#0a0e19'
SHINE = '#f4e6ba'


def paint(kind: str, pose: str, step: int = 0) -> Image.Image:
    im = Image.new('RGBA', (SZ, SZ), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    run = pose == 'run'
    jump = pose == 'jump'
    attack = pose == 'attack'
    hurt = pose == 'hurt'
    bob = (step % 2) if pose == 'idle' else (int(step in (1, 2)) if run else 0)
    y = -bob

    def rect(box, fill):
        x0, y0, x1, y1 = box
        d.rectangle((x0, y0 + y, x1, y1 + y), fill=fill)

    def poly(points, fill):
        d.polygon([(x, yy + y) for x, yy in points], fill=fill)

    def line(points, fill, width=1):
        d.line([(x, yy + y) for x, yy in points], fill=fill, width=width)

    if kind == 'ninja':
        # Wind-blown burgundy bandana, bright band, masked face, and layered
        # indigo robe match the readability of the existing two small mages.
        wrap = '#bd4d63'; deep = '#24405a'; cloak = '#395f82'
        steel = '#7bb9ca'; highlight = '#b4e8df'; boots = '#121d30'
        # Belt tails + scarf flutter behind the head while sprinting.
        poly([(8,9),(3,8+(step%2)),(1,12),(6,12),(10,13)], INK)
        poly([(7,9),(3,9+(step%2)),(3,11),(9,12)], wrap)
        # Two feet and discrete stride silhouettes.
        if jump:
            poly([(12,23),(6,26),(6,29),(10,29),(16,26)],INK)
            poly([(18,23),(22,25),(25,29),(28,28),(24,24)],INK)
            rect((8,27,11,28),steel)
        elif run:
            if step % 2 == 0:
                poly([(11,22),(7,27),(3,28),(3,30),(13,29),(17,24)], INK)
                poly([(19,22),(22,25),(27,26),(28,29),(24,30),(16,26)],INK)
            else:
                poly([(10,22),(6,25),(5,29),(11,30),(17,26)],INK)
                poly([(17,23),(23,25),(27,29),(29,30),(19,29)],INK)
        else:
            poly([(11,22),(9,29),(8,30),(16,30),(17,24)],INK)
            poly([(18,22),(18,29),(20,30),(26,30),(24,27)],INK)
            rect((11,25,14,28),deep)
            rect((21,25,23,28),deep)
        # Layered tunic. The outer outline stays legible over dark maps.
        poly([(10,12),(21,12),(26,16),(25,24),(21,27),(11,26),(7,23),(8,17)],INK)
        poly([(11,14),(20,14),(23,17),(22,23),(19,25),(12,24),(10,22)],cloak)
        poly([(11,14),(13,14),(14,24),(11,23)],steel)
        rect((10,21,23,22),INK)
        rect((13,21,19,21),wrap)
        rect((19,21,20,22),SHINE)
        # Arm animation, with combat pose pointing toward facing right.
        if attack:
            poly([(20,15),(25,16),(27,17),(28,19),(26,21),(21,19)],INK)
            rect((24,17,27,18),steel)
            # 4-point shuriken, distinct from the mage's fireball.
            poly([(29,12),(30,15),(31,16),(29,17),(28,20),(27,17),(25,16),(28,15)], SHINE)
            rect((28,16,29,17),INK)
        elif jump:
            poly([(7,14),(4,11),(3,13),(6,20),(10,19)],INK)
            poly([(21,15),(25,12),(28,14),(24,21),(21,21)],INK)
        elif run:
            arm_offset = 1 if step%2 else -1
            poly([(9,15),(6,17+arm_offset),(7,22+arm_offset),(11,21)],INK)
            poly([(22,15),(25,15-arm_offset),(26,21-arm_offset),(23,22)],INK)
            rect((7,20+arm_offset,9,21+arm_offset),steel)
        else:
            poly([(9,15),(6,16),(6,22),(10,23)],INK)
            poly([(22,15),(25,16),(26,22),(22,23)],INK)
            rect((7,19,8,20),steel)
        # Head, mask and face, plus bright forehead steel band.
        poly([(10,5),(13,3),(21,4),(25,7),(24,13),(21,16),(11,15),(8,11)],INK)
        poly([(11,6),(14,5),(20,5),(23,8),(22,13),(11,13),(10,10)],deep)
        rect((10,8,23,9),wrap)
        rect((14,7,20,7),steel)
        rect((11,10,22,12),INK)
        rect((14,11,15,11),SHINE)
        rect((19,11,20,11),SHINE)
        rect((11,13,22,14),steel)
        # Light edge on the cloak marks the near plane.
        line([(11,16),(12,21)],highlight)
        if hurt:
            rect((13,11,15,11),wrap)
            rect((19,11,21,11),wrap)

    elif kind == 'werewolf':
        # Not a mage recolor: snout, high ears, fur ruff, tail and claws
        # distinguish the silhouette at the same 60px in-game sprite height.
        fur = '#a77d66'; dark = '#493c4a'; light = '#d6b297'
        face = '#efd5ae'; amber = '#f7c268'; inner = '#be817d'
        cloth = '#394656'
        if run:
            if step%2 == 0:
                poly([(12,24),(7,27),(4,29),(5,31),(12,30),(17,25)],INK)
                poly([(19,23),(24,25),(29,28),(28,30),(20,30)],INK)
            else:
                poly([(11,24),(7,25),(5,29),(8,31),(15,28)],INK)
                poly([(19,24),(24,27),(29,29),(27,31),(20,28)],INK)
        elif jump:
            poly([(11,23),(7,26),(7,29),(13,29),(18,25)],INK)
            poly([(20,23),(25,25),(28,28),(26,29),(21,27)],INK)
        else:
            poly([(11,23),(10,28),(8,29),(9,31),(16,31),(17,25)],INK)
            poly([(19,23),(20,29),(21,31),(28,31),(27,29)],INK)
            rect((11,27,13,29),fur)
            rect((22,27,24,29),fur)
        # Tail extends to left and can swing with gait.
        poly([(11,21),(5,20),(3,17+(step%2)),(1,18),(3,24),(9,26)],INK)
        poly([(10,22),(5,22),(4,20+(step%2)),(4,23),(8,24)],fur)
        # Broad shoulders, fur tufts and a charcoal belt.
        poly([(10,12),(20,11),(25,15),(27,22),(23,28),(12,28),(8,23),(7,17)],INK)
        poly([(11,15),(20,14),(24,17),(24,24),(21,26),(13,25),(10,22)],fur)
        poly([(13,14),(16,18),(18,19),(20,14),(20,23),(16,26),(13,22)],light)
        rect((10,23,25,24),cloth)
        rect((16,23,19,24),amber)
        # Arms: claws are part of the action pose, not a copied weapon.
        if attack:
            poly([(22,14),(28,16),(30,18),(30,23),(27,24),(23,20)],INK)
            rect((28,19,29,22),light)
            line([(29,18),(31,18)],face)
            line([(29,20),(31,20)],face)
            line([(29,22),(31,22)],face)
        elif jump:
            poly([(9,15),(5,11),(3,13),(6,21),(10,21)],INK)
            poly([(23,15),(27,12),(30,14),(27,22),(24,22)],INK)
        elif run:
            if step%2 == 0:
                poly([(10,15),(5,17),(6,24),(10,24)],INK)
                poly([(23,15),(28,13),(29,18),(24,22)],INK)
            else:
                poly([(10,15),(6,13),(5,19),(10,22)],INK)
                poly([(24,16),(28,19),(29,25),(24,24)],INK)
        else:
            poly([(10,15),(6,17),(7,24),(11,25)],INK)
            poly([(23,15),(28,17),(28,24),(24,24)],INK)
        rect((7,23,9,24),face)
        rect((26,23,28,24),face)
        # Pointed ear silhouettes, asymmetric snout towards right.
        poly([(10,10),(9,2),(12,3),(15,7),(18,7),(21,2),(25,3),(24,10)],INK)
        poly([(11,8),(11,4),(14,7)],inner)
        poly([(20,7),(23,4),(23,8)],inner)
        poly([(10,8),(13,6),(22,7),(25,11),(23,16),(19,17),(12,16),(9,13)],INK)
        poly([(11,9),(15,7),(21,8),(23,11),(21,15),(12,15),(11,12)],fur)
        poly([(16,10),(23,10),(27,11),(29,13),(27,15),(22,15),(18,14)],INK)
        poly([(17,11),(24,11),(27,12),(27,14),(22,14)],face)
        rect((25,11,27,12),INK)
        rect((13,11,14,11),amber)
        rect((19,11,20,11),amber)
        rect((16,14,18,14),light)
        if hurt:
            rect((13,11,15,11),inner)
            rect((19,11,21,11),inner)
            line([(18,12),(20,14)],INK)
    else:
        raise ValueError(kind)
    return im


def produce(kind: str) -> None:
    poses = [('idle',0),('idle',1)] + [('run',i) for i in range(4)] + [
        ('jump',0), ('attack',0), ('hurt',0)
    ]
    files = []
    for pose,frame in poses:
        out = OUT / f'{kind}_{pose}_{frame}.png'
        im = paint(kind, pose,frame)
        im.save(out,optimize=True)
        files.append(out)
    # Purely diagnostic contact sheet, not used as a gameplay texture.
    sheet = Image.new('RGBA',(32*len(files),32))
    for index,path in enumerate(files):
        sheet.alpha_composite(Image.open(path).convert('RGBA'),(32*index,0))
    sheet.save(OUT/f'{kind}_poses.png',optimize=True)
    print(kind, 'poses:', len(files), 'alpha bboxes:',
          [Image.open(f).getbbox() for f in files])


if __name__ == '__main__':
    for name in ('ninja','werewolf'):
        produce(name)
