"""Deterministic hand-authored pixel shelves from geometric primitives only.

The three variants fit the room's blue-gray paneling, warm wood, book colors,
and pixel-sharp depth. No online assets or image-generation tools are used.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import random
OUT=Path(__file__).parent/'sprites';OUT.mkdir(exist_ok=True)
PAL=[(155,91,74,255),(198,140,98,255),(87,148,157,255),(104,115,169,255),(156,165,117,255),(191,181,152,255),(169,105,132,255)]

def make(name,w,seed):
    rng=random.Random(seed);h=48
    img=Image.new('RGBA',(w,h));d=ImageDraw.Draw(img)
    # Structural top at pixel 0: players' feet align to the actual one-way
    # collider. Deep shadow and side braces keep the shelves grounded on wall.
    d.rectangle([2,4,w-3,45],fill=(32,43,56,220))
    d.rectangle([3,5,w-4,39],fill=(60,75,83,255))
    d.rectangle([7,7,w-8,17],fill=(31,39,54,255))
    d.rectangle([7,22,w-8,34],fill=(32,42,54,255))
    # Irregular book heights, but all inside the cabinet; no physics collision
    # through the body, since the cabinet is a one-way furniture platform.
    for y0,y1 in [(6,17),(22,34)]:
        x=9
        while x<w-12:
            bw=rng.choice([3,4,5,6]);top=y0+rng.choice([0,1,2]);bottom=y1-rng.choice([0,1]);color=PAL[rng.randrange(len(PAL))]
            d.rectangle((x,top,min(x+bw,w-10),bottom),fill=color)
            d.line((x,top,x,bottom),fill=(38,46,59,160))
            if bw>=5:d.line((x+2,top+2,x+2,min(bottom,top+5)),fill=(233,207,164,200))
            x+=bw+1
    # Crosspiece, top bevel, bottom lip: no randomized overall proportions.
    d.rectangle((1,0,w-2,3),fill=(32,41,55,255))
    d.line((3,0,w-4,0),fill=(225,199,150,255),width=1)
    d.line((2,1,w-3,1),fill=(142,110,82,255),width=1)
    d.rectangle((0,18,w-1,21),fill=(43,50,60,255))
    d.line((2,18,w-3,18),fill=(187,148,106,255))
    d.rectangle((0,39,w-1,43),fill=(36,45,57,255))
    d.line((2,39,w-3,39),fill=(191,159,112,255))
    d.rectangle((3,44,12,47),fill=(42,53,64,210))
    d.rectangle((w-13,44,w-4,47),fill=(42,53,64,210))
    # Narrow lit side panel reads as depth from the scene's left light.
    d.line((3,4,3,38),fill=(164,132,101,255),width=1)
    d.line((w-4,4,w-4,38),fill=(24,35,48,255),width=1)
    img.save(OUT/name,optimize=True)
    return img

variants=[('wall_bookshelf_oak.png',96,13),('wall_bookshelf_teal.png',112,29),('wall_bookshelf_walnut.png',96,51)]
for name,w,seed in variants:make(name,w,seed)
# A montage for quick inspector matching only (not loaded by the game).
canvas=Image.new('RGBA',(112*3,48),(0,0,0,0))
for i,(name,w,seed) in enumerate(variants):canvas.alpha_composite(Image.open(OUT/name),(i*112,0))
canvas.save(OUT/'shelves_preview.png',optimize=True)
print('SHELVES',variants)
