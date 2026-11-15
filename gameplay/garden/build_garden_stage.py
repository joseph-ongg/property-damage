#!/usr/bin/env python3
"""Separate Art Team Garden pixels into reversible, destructible prop layers.

The 426x286 Piskel source remains unchanged. We map it to the 960x540 game
viewport at exact integer 2x nearest-neighbor scale, then separate original
plant-colored pixels (and their one-pixel outlines) into three transparent
visual layers. The composite is visually identical to the original source;
individual props can now genuinely disappear as their HP reaches zero.

This is local programmatic pixel manipulation, no image generator or external
copyrighted media. All source pixel content is credited to Art & Audio.
"""
from __future__ import annotations
import json
import random
from pathlib import Path
from PIL import Image, ImageDraw
HERE = Path(__file__).resolve().parent
SRC = HERE.parent / "art_team" / "exported" / "garden.png"
OUT = HERE / "art_generated"
OUT.mkdir(parents=True, exist_ok=True)
SIZE = (960, 540)
ORIGIN = (54, -16)
SCALE = 2
COLORS = {
    "rose": {(226,41,22), (189,35,37), (193,58,47),
             (43,114,64),(0,109,0),(13,76,32),(244,137,80),
             (148,117,86), (158,66,17)},
    "tree": {(91,85,79),(129,97,79),(111,76,41),(148,117,86),
             (163,210,0),(148,191,8)},
    "mushrooms": {(226,41,22),(189,35,37),(193,58,47),(98,121,193),
                  (117,137,219),(58,80,169),(148,117,86),(197,166,163),
                  (212,155,124),(244,137,80),(111,76,41)},
}
# source-pixel areas, to keep rails, fence and unrelated colors unchanged
RECTS = {
    "rose": (0, 39, 174, 246),
    "tree": (252, 0, 426, 246),
    "mushrooms": (170, 207, 343, 249),
}
source = Image.open(SRC).convert("RGBA")
sw,sh=source.size
masks={kind:Image.new('1',source.size,0) for kind in COLORS}
for kind, palette in COLORS.items():
    mask=masks[kind]
    px=mask.load()
    x0,y0,x1,y1=RECTS[kind]
    for sy in range(max(0,y0),min(sh,y1)):
        for sx in range(max(0,x0),min(sw,x1)):
            rgba=source.getpixel((sx,sy))
            if rgba[3] and rgba[:3] in palette:
                # Exclude the broad grass slab from tree silhouette; also
                # keep the gray fence untouched outside the dark tree trunk.
                if kind=='tree' and sy>239:
                    continue
                if kind=='mushrooms' and sx>322 and rgba[:3] in {(148,117,86),(111,76,41)}:
                    continue
                px[sx,sy]=1
# Expand by one source pixel to capture black boundaries and line detail.
for kind,mask in list(masks.items()):
    old=mask.copy()
    pixels=old.load()
    expanded=mask.load()
    x0,y0,x1,y1=RECTS[kind]
    for y in range(max(0,y0),min(sh,y1)):
        for x in range(max(0,x0),min(sw,x1)):
            if not pixels[x,y]:
                continue
            for dx,dy in ((-1,0),(1,0),(0,-1),(0,1)):
                xx,yy=x+dx,y+dy
                if x0<=xx<x1 and y0<=yy<y1 and 0<=xx<sw and 0<=yy<sh:
                    if source.getpixel((xx,yy))[3]>0:
                        expanded[xx,yy]=1
# An overlapping pixel is owned by the most specific layer. This is an
# exact partition: the background + all props reproduce the source map.
prior=set()
for kind in ('mushrooms','rose','tree'):
    m=masks[kind]
    for y in range(sh):
        for x in range(sw):
            if m.getpixel((x,y)) and (x,y) in prior:
                m.putpixel((x,y),0)
            if m.getpixel((x,y)):
                prior.add((x,y))
# Draw a dark fantasy sky, tiny star particles and a two-tone pixel border
# outside the original pixels. The original pixel palette is untouched.
base=Image.new('RGBA', SIZE,(19,23,45,255))
d=ImageDraw.Draw(base)
for y in range(540):
    if y<476:
        shade=(18+y//43,22+y//44,43+y//45,255)
        d.line((0,y,959,y),fill=shade)
random.seed(1997)
for _ in range(160):
    x=random.randrange(960);y=random.randrange(365)
    c=(163,177,224,220) if random.randrange(4) else (247,210,150,255)
    d.point((x,y),fill=c)
for x in range(0,960,16):
    d.rectangle((x,476,x+15,539),fill=(163,210,0,255) if x%32==0 else (148,191,8,255))
for y in (476,477,478):
    d.line((0,y,960,y),fill=(199,225,67,255))
for sx in (0,952):
    d.rectangle((sx,0,sx+7,474),fill=(23,29,55,255))
    for y in range(76,474,60):
        d.point((sx+3,y),fill=(247,205,128,255))
layers={}
background_source=Image.new('RGBA',source.size,(0,0,0,0))
for y in range(sh):
    for x in range(sw):
        if source.getpixel((x,y))[3] and (x,y) not in prior:
            background_source.putpixel((x,y),source.getpixel((x,y)))
for kind,mask in masks.items():
    layer=Image.new('RGBA',source.size,(0,0,0,0))
    for y in range(sh):
        for x in range(sw):
            if mask.getpixel((x,y)):
                layer.putpixel((x,y),source.getpixel((x,y)))
    stage=Image.new('RGBA',SIZE,(0,0,0,0))
    # PIL alpha_composite does not support negative destination y; paste
    # the scaled transparent layer and let PIL crop the offscreen pixels.
    big=layer.resize((sw*SCALE,sh*SCALE),Image.Resampling.NEAREST)
    stage.paste(big,(ORIGIN[0],ORIGIN[1]))
    stage.save(OUT/f'garden_prop_{kind}.png',optimize=True)
    layers[kind]=stage
canvas=base.copy()
bg_big=background_source.resize((sw*SCALE,sh*SCALE),Image.Resampling.NEAREST)
canvas.paste(bg_big,ORIGIN,bg_big)
canvas.save(OUT/'garden_stage_background.png',optimize=True)
# Build a cell-exact flammable mask from actual extracted plant pixels,
# sampling the 16x16 Godot material grid. 1=rose, 2=tree, 3=mushroom.
tagged=Image.new('RGB',(60,34),(0,0,0))
for gx in range(60):
    for gy in range(34):
        counts={}
        for kind,stage in layers.items():
            region=stage.crop((gx*16,gy*16,(gx+1)*16,(gy+1)*16))
            rgba_bytes = region.tobytes()
            counts[kind] = sum(rgba_bytes[i] > 0 for i in range(3, len(rgba_bytes), 4))
        winner=max(counts,key=counts.get)
        if counts[winner]>=12:
            tagged.putpixel((gx,gy),{'rose':(255,0,0),'tree':(0,255,0),'mushrooms':(0,0,255)}[winner])
tagged.save(OUT/'garden_fuel_mask.png',optimize=True)
# Pixel-level round trip: recombining background and alive props is exactly
# the original Piskel art (plus atmospheric sky/outer edge decoration).
original=source.resize((sw*SCALE,sh*SCALE),Image.Resampling.NEAREST)
joint=canvas.copy()
for name in ('rose','tree','mushrooms'):
    joint.alpha_composite(layers[name])
expected=base.copy(); expected.paste(original,ORIGIN,original)
# Alpha-composite over opaque stage and compare only RGB for tinted alpha.
if joint.tobytes()!=expected.tobytes():
    raise AssertionError('Partitioned stage does not reconstruct original art pixels')
manifest={
 'source':str(SRC.relative_to(HERE.parent.parent)),'source_size':list(source.size),
 'integer_scale':2,'stage_size':list(SIZE),'origin':list(ORIGIN),
 'parts':{kind:{'source_mask_pixels':sum(masks[kind].getpixel((x,y)) for y in range(sh) for x in range(sw)),
                 'cells':sum(tagged.getpixel((x,y))=={'rose':(255,0,0),'tree':(0,255,0),'mushrooms':(0,0,255)}[kind] for y in range(34) for x in range(60))}
         for kind in masks},
 'exact_source_pixel_reconstruction':True,
}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Garden stage parts:', manifest['parts'])
print('Original source reconstructed exactly using separate destructible layers')
