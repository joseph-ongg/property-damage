#!/usr/bin/env python3
"""Reversible Art Team Garden Piskel separation for genuine moving props.

No invented sprites: original garden.piskel and exported garden.png remain
untouched. A sparse authored-color mask lifts the existing fence pixels into
eight 4-HP sections, the two mushrooms into separate images, and the painted
hose nozzle into a portable image. The composite at starting positions MUST
be pixel-for-pixel identical to the source (including transparent sky).
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
from PIL import Image

HERE=Path(__file__).resolve().parent
SOURCE=HERE.parent/"art_team/exported/garden.png"
OUT=HERE/"original_art_parts"
OUT.mkdir(exist_ok=True)
src=Image.open(SOURCE).convert("RGBA")
assert src.size==(426,286)
width,height=src.size
pixels=src.load()
nonzero=lambda x,y: 0<=x<width and 0<=y<height and pixels[x,y][3]==255

def select_from_original(box, colors, allowed_neighbors, steps=2):
    x0,y0,x1,y1=box
    seeds={(x,y) for x in range(x0,x1) for y in range(y0,y1)
           if nonzero(x,y) and pixels[x,y][:3] in colors}
    assert seeds,("Empty Art Team crop",box)
    chosen=set(seeds)
    frontier=set(seeds)
    for step in range(steps):
        following=set()
        for x,y in frontier:
            for dx,dy in ((-1,0),(1,0),(0,-1),(0,1)):
                xx,yy=x+dx,y+dy
                if x0<=xx<x1 and y0<=yy<y1 and nonzero(xx,yy):
                    if pixels[xx,yy][:3] in allowed_neighbors and (xx,yy) not in chosen:
                        following.add((xx,yy))
        chosen |= following
        frontier=following
    return chosen

# Original red/blue mushroom caps (plus their adjacent authored black outlines
# and green stalks), spatially confined to the two existing source motifs.
mushroom_red=select_from_original((168,205,195,246),
    {(189,35,37),(226,41,22)}, {(0,0,0),(43,114,64)},3)
mushroom_blue=select_from_original((195,205,228,246),
    {(98,121,193),(117,137,219),(58,80,169)},
    {(0,0,0),(43,114,64)},3)
assert mushroom_red.isdisjoint(mushroom_blue)

# Original black-gray pipe on the grass; no new hose texture is drawn.
nozzle=select_from_original((244,231,282,250),
    {(96,96,96),(192,192,192)},
    {(0,0,0),(162,164,150)},2)
assert nozzle.isdisjoint(mushroom_red|mushroom_blue)

stone={(162,164,150),(191,193,180)}
fence={(x,y) for y in range(128,245) for x in range(width)
       if nonzero(x,y) and pixels[x,y][:3] in stone}
border=set()
for x,y in fence:
    for dx,dy in ((-1,0),(1,0),(0,-1),(0,1)):
        xx,yy=x+dx,y+dy
        if 0<=xx<width and 128<=yy<245 and nonzero(xx,yy) and pixels[xx,yy][:3]==(0,0,0):
            border.add((xx,yy))
# Roses overlap the stone in the original single-layer Piskel.
# Preserve line art within 2 original pixels of the rose/vine palette.
rose_colors={(226,41,22),(189,35,37),(193,58,47),
             (43,114,64),(0,109,0),(13,76,32),(244,137,80)}
def next_to_rose(x,y):
    for dx in range(-2,3):
        for dy in range(-2,3):
            xx,yy=x+dx,y+dy
            if nonzero(xx,yy) and pixels[xx,yy][:3] in rose_colors:
                return True
    return False
border={pt for pt in border if not next_to_rose(*pt)}
fence=(fence|border)-(mushroom_red|mushroom_blue|nozzle)
assert fence.isdisjoint(mushroom_red|mushroom_blue|nozzle)

masks={}
for idx in range(8):
    x0=round(idx*width/8)
    x1=round((idx+1)*width/8)
    masks[f"fence_segment_{idx+1:02}.png"]=((x0,0,x1,height),
        {(x,y) for (x,y) in fence if x0<=x<x1})
masks["mushroom_red.png"]=((168,205,195,246),mushroom_red)
masks["mushroom_blue.png"]=((195,205,228,246),mushroom_blue)
masks["hose_nozzle.png"]=((244,231,282,250),nozzle)

base=src.copy()
for _,(_,mask) in masks.items():
    for x,y in mask:
        base.putpixel((x,y),(0,0,0,0))
base.save(OUT/"garden_without_dynamic_props.png",optimize=True)

image_parts={}
count={}
for name,(bounds,mask) in masks.items():
    x0,y0,x1,y1=bounds
    part=Image.new("RGBA",(x1-x0,y1-y0),(0,0,0,0))
    for x,y in mask:
        part.putpixel((x-x0,y-y0),pixels[x,y])
    part.save(OUT/name,optimize=True)
    image_parts[name]=(bounds,part)
    count[name]=len(mask)
assert min(count.values())>20,count

assembled=base.copy()
for bounds,part in image_parts.values():
    assembled.alpha_composite(part,(bounds[0],bounds[1]))
assert assembled.tobytes()==src.tobytes(),"Source art reconstruction must be pixel-exact"
record={
 "source":"gameplay/art_team/exported/garden.png",
 "source_sha256":hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
 "original_dimensions":[width,height],
 "fence_segments":8,"hp_per_fence_segment":4,
 "source_art_pixels":count,
 "exact_piskel_pixel_reconstruction":True,
 "added_original_art_pixels":0,
 "artwork_created":False,
}
(OUT/"manifest.json").write_text(json.dumps(record,indent=2)+"\n")
# Cache the *source-exact* fence fire footprint by 16px Simulation cell.
# The editable Garden scene displays garden.piskel at 2x scale and offset
# (54,-16). Each original source pixel center is therefore (55+2*x,-15+2*y).
# Runtime no longer traverses all 120k image pixels on every arena load.
fire_footprints={}
for idx in range(8):
    f=f"fence_segment_{idx+1:02}.png"
    occupied={(int((55+2*x)//16),int((-15+2*y)//16)) for x,y in masks[f][1]}
    fire_footprints[str(idx+1)]=[list(c) for c in sorted(occupied)]
(OUT/"fence_fire_cells.json").write_text(json.dumps({
    "source_sha256": record["source_sha256"],
    "cell_size":16,
    "stage_offset":[54,-16],
    "stage_art_scale":2,
    "cells":fire_footprints
},indent=2)+"\n")
print("Fence fire-mask Simulation cells", {k:len(v) for k,v in fire_footprints.items()})
print("PASS pixel-exact reconstruction: fence 8, red/blue mushrooms, hose nozzle",count)
