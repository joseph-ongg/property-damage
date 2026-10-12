"""Godot 960x540 MSD arena redraw based on the actual Art subteam PPT tiles.

The original PPT furniture/window/clock tiles have already been extracted by
`gameplay/art/import_midsem_art.py`. This only *composites local raster art*;
no AI image generation or new gameplay collision layers are involved.
"""
from PIL import Image, ImageDraw
import math
from pathlib import Path
import random
D=Path(__file__).resolve().parent
rng=random.Random(1906)
W,H=480,270
im=Image.new('RGBA',(W,H),'#47515d')
d=ImageDraw.Draw(im)
def box(rect,color):d.rectangle(rect,fill=color)
def line(points,color,width=1):d.line(points,fill=color,width=width)

# Paint the far wall first. Restrained architectural depth, not blurred HD art.
# All geometry is painted at half resolution and doubled with NEAREST below.
# The floor/world physics remains independent from every visual layer.
for y in range(249):
    shade=int(67+16*y/250)
    line((0,y,479,y),(shade,shade+5,shade+13,255))
# Wall paneling recedes behind art: dark coves, gold trim, darkening into
# the corners to give the room visual depth even with a locked 2D camera.
for x in range(8,480,32):
    line((x,16,x,247),'#4a5661')
for y in [6,14,122,125,246]:
    box((0,y,479,y+2),'#303943')
    line((3,y+1,475,y+1),'#957e70')
for x in range(24,463,64):
    box((x,130,x+53,229),'#515d65')
    box((x+2,133,x+51,227),'#48535e')
    line((x+2,133,x+51,133),'#67737b')
    line((x+3,226,x+50,226),'#313c47')
# Subtle ambient occlusion where ceiling/corners meet the wall.
for i in range(8):
    ink=(45+i,54+i,66+i,255)
    line((8+i,17,8+i,242),ink)
    line((471-i,17,471-i,242),ink)
for y in [3,5,9,13,118,126]:
    line((5,y,474,y),'#394451')
# Design Team "Crime Scene" layout (PPT slide 12): left window,
# bookshelves on the left, central work desk/monitor, upper-wall AC, wall
# clock and refrigerator storage on the right. The older giant moon/city
# window was not in the Design diagram and obscured this room's silhouette.
# Keep the Art Team's small plant window further below and paint a compact
# landscape picture above the monitor instead of a full-height cityscape.
box((201,44,277,99),'#293640')
box((204,47,274,96),'#c0a48d')
box((209,51,269,92),'#486273')
d.polygon([(210,89),(229,67),(240,81),(253,59),(268,85),(268,91)],fill='#82929a')
box((209,88,269,91),'#7b8678')
for sx,sy in ((218,59),(259,56),(265,65)):
    box((sx,sy,sx+1,sy+1),'#f4dbab')
# The wall below this picture is intentionally clear so the table, monitor,
# fan and book prompts do not compete with background furniture.
for x,y in ((56,61),(356,66)):
    box((x-3,y-3,x+36,y+28),'#2c3035')
    box((x,y,x+33,y+25),'#af977d')
    box((x+3,y+3,x+30,y+21),'#415f72')
    d.polygon([(x+3,y+20),(x+14,y+8),(x+23,y+20)],fill='#7c8597')
for x in (139,343):
    box((x-5,109,x+5,113),'#c6a481')
    box((x-3,106,x+3,109),'#ffe3a4')
    box((x-1,103,x+1,107),'#fff4c6')
# Design Team map/collision silhouettes: bookshelf at y344, desk at y411,
# refrigerator top at y350, and physical floor at y498. No new colliders.
box((0,249,479,269),'#635d5c')
for yy in [252,260,269]:line((0,yy,479,yy),'#8c7c6b')
# Floor boards are horizontal in perspective, with stepped highlights and
# deeper seams away from the wall. The room still has the same 498px floor.
for x in range(0,480,29):
    line((x,251,x,270),'#514c51')
    line((x+1,251,x+1,269),'#77706a')
for y in (251,258,266):
    line((5,y,474,y),'#443c42')
    line((5,y+1,474,y+1),'#877768')
for x in range(14,480,58):
    line((x,258,x,264),'#655a57')
# Rug gets a deep edge and patterned top; completely visual.
box((174,252,325,267),'#513c49')
box((182,254,320,264),'#9f7165')
for x in range(189,319,22):
    d.polygon([(x,259),(x+5,254),(x+10,259),(x+5,264)],fill='#c4a57c')
# Left couch/reading corner - no invisible collision added.
box((15,199,68,246),'#313541')
box((19,195,66,227),'#945b5e')
box((23,200,61,226),'#b87570')
box((15,224,72,246),'#ae756b')
box((17,242,69,250),'#443843')
box((31,208,42,219),'#dca47f')
# Table platform's actual collision surface is y=405 in world space.
# Keep the visible tabletop at y=404..410 instead of five pixels too low.
box((186,202,300,210),'#443b42')
box((188,202,298,205),'#b48f70')
box((192,212,200,248),'#655153')
box((287,212,295,248),'#655153')
for x in [194,208,286]:box((x,209,x+4,213),'#d5b78a')
box((182,246,302,249),'#514953')
# Art-team fridge is drawn by Appliances at x735..825 / y344..498.
# Don't paint the former extra-wide 136px platform behind its top.
box((365,171,414,175),'#332e36')
box((366,172,413,173),'#ecc590')
# Bookshelf platform at world 344; other shelves are inside art.
box((72,169,168,173),'#42353a')
box((72,169,168,170),'#f4d68e')
# Small framed posters and shelf brackets.
for x in (78,163): box((x,175,x+2,179),'#9d795d')
for x in (189,295):box((x,211,x+3,217),'#ab815f')
# Consistent pixel treatment around the collision walls.
for x in (0,475):
    box((x,0,x+5,249),'#343943')
    box((x+2,0,x+2,248),'#a68b7d')

# Use the team's actual flat-color furniture/window/clock designs from slide 12.
# Render in 480x270 image coordinates before 2x nearest-neighbor upscale.
def art(name,rect):
    x,y,w,h=rect
    sprite=Image.open(D/f'team_{name}.png').convert('RGBA')
    sprite=sprite.resize((w,h),Image.Resampling.NEAREST)
    im.alpha_composite(sprite,(x,y))
# Original art ratio: shelf 178x230; use two narrow equal modules rather
# than squeezing a tall bookshelf into a single artificially wide cabinet.
# The combined modules span the existing bookshelf collision platform.
box((73,231,167,248),'#554139')
box((73,231,167,233),'#c9a36f')
for base_x in (75,120):
    art('shelf',(base_x,173,45,60))
# Keep the plant window below the persistent top HUD, preserve 134:103 ratio.
art('window',(41,40,81,62))
# The PPT collage clips off the right side of its clock (team_clock.png has
# opaque pixels right through its last column). NEVER edit the Art Team file.
# Reconstruct a complete hand-pixelled clock at the same on-wall position.
def whole_clock(cx=417, cy=70, radius=20):
    # A small cast shadow makes the object project from the wall.
    d.ellipse((cx-radius+2,cy-radius+4,cx+radius+3,cy+radius+5),fill='#252e38')
    d.ellipse((cx-radius-1,cy-radius-1,cx+radius+1,cy+radius+1),fill='#282b32')
    d.ellipse((cx-radius+1,cy-radius+1,cx+radius-1,cy+radius-1),fill='#8a6856')
    d.ellipse((cx-radius+3,cy-radius+2,cx+radius-3,cy+radius-3),fill='#d7c6ad')
    d.ellipse((cx-radius+5,cy-radius+4,cx+radius-5,cy+radius-5),fill='#f2e8d6')
    d.arc((cx-radius+2,cy-radius+2,cx+radius-2,cy+radius-2),200,320,fill='#f9dfb7',width=2)
    for hour in range(12):
        theta=math.radians(hour*30-90)
        r1=radius-8 if hour%3==0 else radius-7
        r2=radius-5
        x1=cx+round(math.cos(theta)*r1)
        y1=cy+round(math.sin(theta)*r1)
        x2=cx+round(math.cos(theta)*r2)
        y2=cy+round(math.sin(theta)*r2)
        d.line((x1,y1,x2,y2),fill='#49404a',width=2 if hour%3==0 else 1)
    # Two independent hands, centered hub, and short highlight. No motion
    # dependency: the clock remains a faithful pixel prop on a static map.
    d.line((cx,cy,cx+10,cy-9),fill='#413843',width=2)
    d.line((cx,cy,cx-2,cy+12),fill='#413843',width=3)
    d.rectangle((cx-2,cy-2,cx+1,cy+1),fill='#b97c50')
    d.point((cx,cy),fill='#ffe0a4')
whole_clock()
# Add platform edge bright pixels above the furniture silhouettes.
d=ImageDraw.Draw(im)
for a,b,y in [(75,166,169),(188,298,202),(366,414,172)]:
    for x in range(a,b,14): box((x,y,x+5,y+1),'#ffe7a9')
# Contact shadows: foot/furniture grounding, separate from collision.
# Applying AFTER furniture would obscure their pixel art, so keep contact
# at the floor/wall boundary only and to the sides of footprints.
for a,b in [(15,74),(76,165),(183,302),(361,419)]:
    box((a+3,248,b+5,250),'#292d37')
    line((a+7,251,b+2,251),'#443d40')
# Local co-op spawn brackets; P1 blue, P2 red (match Character design).
for x,c in ((40,'#4d9af2'),(442,'#f05e61')):
    box((x-17,247,x-10,248),c);box((x+10,247,x+17,248),c)
# Build separate transparent *depth layers* rather than baking all light
# into the same opaque room. This leaves collision, players and interface
# untouched and permits tuning the "HD-2D inspired" atmosphere independently.
lighting=Image.new('RGBA',(W,H),(0,0,0,0))
ld=ImageDraw.Draw(lighting)
# Stepped lamp pools and stained-glass moonlight; no blur or filtering.
for cx,cy,rx,ry,r,g,b in [(79,104,73,120,116,165,218),
                          (247,87,88,67,239,186,116),
                          (280,196,71,47,83,179,222)]:
    for level in range(6,0,-1):
        f=level/6.0
        opacity=10 if level>=4 else 14
        ld.ellipse((round(cx-rx*f),round(cy-ry*f),round(cx+rx*f),round(cy+ry*f)),fill=(r,g,b,opacity))
# Soft-edged perspective rays made of layered translucent polygons.
for alpha,poly in [(17,[(42,79),(89,79),(154,248),(102,248)]),
                   (9,[(72,90),(122,90),(190,248),(157,248)])]:
    ld.polygon(poly,fill=(163,208,234,alpha))
# Subtle wall/floor separation and side-room shadow, not screen-space blur.
for i in range(11):
    opacity=6 if i<5 else 3
    ld.line((6+i,129,6+i,246),fill=(12,20,29,opacity))
    ld.line((473-i,129,473-i,246),fill=(12,20,29,opacity))
for y in range(241,249):
    ld.line((10,y,471,y),fill=(15,17,26,7))

# Foreground plant silhouettes only at far corners. Players and furniture
# stay unobstructed in the center of the arena; low-key close parallax cues.
front=Image.new('RGBA',(W,H),(0,0,0,0))
fd=ImageDraw.Draw(front)
for root_x,sgn in ((7,1),(473,-1)):
    fd.line((root_x,249,root_x+10*sgn,202),fill=(30,53,53,218),width=3)
    for i,(dx,dy) in enumerate(((5,13),(13,24),(3,36),(17,42),(8,53))):
        px=root_x+dx*sgn
        py=249-dy
        fd.polygon([(px,py),(px+sgn*(8+i%3),py-10),(px+sgn*15,py-4)],fill=(36,73,66,170))
        fd.line((px,py,px+sgn*10,py-5),fill=(85,134,106,115))
    fd.rectangle((root_x-6,246,root_x+6,257),fill=(53,49,52,231))
    fd.line((root_x-5,247,root_x+5,247),fill=(169,124,87,225),width=2)
# Foreground shelf/apron gives table physical depth without hiding the actors.
fd.rectangle((182,247,301,249),fill=(40,31,43,150))
fd.line((185,247,300,247),fill=(169,119,90,125),width=1)

for filename,source in [
    ('living_room_pixel.png',im),
    ('living_room_lighting.png',lighting),
    ('living_room_foreground.png',front),
]:
    source.resize((960,540),Image.Resampling.NEAREST).save(D/filename,optimize=True)
print('Art Team room + repaired clock + background/light/foreground depth layers', (960,540))
