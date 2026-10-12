"""Godot 960x540 MSD arena redraw based on the actual Art subteam PPT tiles.

The original PPT furniture/window/clock tiles have already been extracted by
`gameplay/art/import_midsem_art.py`. This only *composites local raster art*;
no AI image generation or new gameplay collision layers are involved.
"""
from PIL import Image, ImageDraw
from pathlib import Path
import random
D=Path(__file__).resolve().parent
rng=random.Random(1906)
W,H=480,270
im=Image.new('RGBA',(W,H),'#47515d')
d=ImageDraw.Draw(im)
def box(rect,color):d.rectangle(rect,fill=color)
def line(points,color,width=1):d.line(points,fill=color,width=width)

# Art-team-style pale slate walls, timber rails and a readable plain floor.
for y in range(249):
    shade=int(67+16*y/250)
    line((0,y,479,y),(shade,shade+5,shade+13,255))
for x in range(8,480,32):
    line((x,16,x,247),'#4a5661')
for y in [6,14,246]:
    box((0,y,479,y+2),'#2f343d')
    line((3,y+1,475,y+1),'#a18e86')
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
for x in range(0,480,29):line((x,250,x,270),'#514c51')
box((174,252,325,267),'#714b50')
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
art('clock',(397,51,40,40))
# Add platform edge bright pixels above the furniture silhouettes.
d=ImageDraw.Draw(im)
for a,b,y in [(75,166,169),(188,298,202),(366,414,172)]:
    for x in range(a,b,14): box((x,y,x+5,y+1),'#ffe7a9')
# Local co-op spawn brackets; P1 blue, P2 red (match Character design).
for x,c in ((40,'#4d9af2'),(442,'#f05e61')):
    box((x-17,247,x-10,248),c);box((x+10,247,x+17,248),c)
# Only now double to 960x540 with no anti-aliasing.
im.resize((960,540),Image.Resampling.NEAREST).save(D/'living_room_pixel.png',optimize=True)
print('Repainted Godot room using PPT Art subteam assets', (960,540))
