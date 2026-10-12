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
# A long background moonlit window, inspired by the Art group's window plant.
box((185,35,298,120),'#182333')
for y in range(40,115):
    blue=int(45+28*y/120)
    line((190,y,292,y),(28,50,blue+15,255))
d.ellipse((268,52,281,65),fill='#ffedb4')
d.ellipse((272,48,285,61),fill='#263d58')
for i in range(40):
    x=rng.randrange(192,291);y=rng.randrange(42,111)
    if (x+y)%4==0:d.point((x,y),fill='#acc1cb')
for x in range(192,293,14):
    h=rng.randint(14,24)
    box((x,115-h,x+12,115),'#293b4a')
    for wy in range(115-h+5,114,7):
        box((x+3,wy,x+4,wy+2),'#d9ac77')
for rect in [(184,34,189,121),(293,34,299,121),(187,35,297,40),(187,115,297,120),(236,39,240,117)]:
    box(rect,'#b08f72')
line((187,80,297,80),'#b8a08b',3)
# Curtain, picture frames, lamps; colorful but do not occlude player physics.
for x in (181,300):
    box((x,37,x+5,120),'#704f5a')
    for y in range(46,116,13):box((x+2,y,x+3,y+6),'#a97672')
for x,y in ((56,61),(356,66)):
    box((x-3,y-3,x+36,y+28),'#2c3035')
    box((x,y,x+33,y+25),'#af977d')
    box((x+3,y+3,x+30,y+21),'#415f72')
    d.polygon([(x+3,y+20),(x+14,y+8),(x+23,y+20)],fill='#7c8597')
for x in (139,343):
    box((x-5,109,x+5,113),'#c6a481')
    box((x-3,106,x+3,109),'#ffe3a4')
    box((x-1,103,x+1,107),'#fff4c6')
# Main furniture silhouettes, with play surfaces matching real Godot bodies:
# bookshelf at world y344, table y411, fridge top y350, floor y498.
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
# Table, world coordinates [372..598] x [411] remain unchanged.
box((186,205,300,213),'#443b42')
box((188,205,298,208),'#b48f70')
box((192,212,200,248),'#655153')
box((287,212,295,248),'#655153')
for x in [194,208,286]:box((x,209,x+4,213),'#d5b78a')
box((182,246,302,249),'#514953')
# Fridge top is a *separate* one-way platform: no new physics here.
box((357,174,425,178),'#332e36')
box((358,175,424,176),'#ecc590')
# Bookshelf platform at world 344; other shelves are inside art.
box((72,170,168,174),'#42353a')
box((72,171,168,171),'#f4d68e')
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
art('shelf',(73,174,94,74))
art('window',(41,31,81,69))
art('clock',(397,51,40,40))
# Add platform edge bright pixels above the furniture silhouettes.
d=ImageDraw.Draw(im)
for a,b,y in [(75,166,170),(188,298,205),(358,424,174)]:
    for x in range(a,b,14): box((x,y,x+5,y+1),'#ffe7a9')
# Local co-op spawn brackets; P1 blue, P2 red (match Character design).
for x,c in ((40,'#4d9af2'),(442,'#f05e61')):
    box((x-17,247,x-10,248),c);box((x+10,247,x+17,248),c)
# Only now double to 960x540 with no anti-aliasing.
im.resize((960,540),Image.Resampling.NEAREST).save(D/'living_room_pixel.png',optimize=True)
print('Repainted Godot room using PPT Art subteam assets', (960,540))
