#!/usr/bin/env python3
"""Original procedural *temporary* combat poses for missing Art Team frames.

The team delivered Ninja/Wolf idle, walk and Wolf damage. We keep those
source frames intact and extend them with simple locally drawn 32x32
motion/runic overlays. These images are NOT official Art & Audio deliverables.
No third-party anime characters, images or generative tools are involved.
"""
from pathlib import Path
from PIL import Image, ImageDraw
HERE=Path(__file__).resolve().parent
S=HERE.parent/'art_team'/'exported'
O=HERE/'generated';O.mkdir(exist_ok=True)
T=(102,232,216,255); W=(236,246,255,255); L=(204,171,245,255)
R=(241,115,153,255); G=(246,209,131,255); D=(29,35,61,210)

def base(which,dx=0,dy=0):
    src=Image.open(S/which).convert('RGBA')
    out=Image.new('RGBA',(32,32))
    out.paste(src,(dx,dy),src)
    return out

def save(im,name):
    im.save(O/name,optimize=True)
    print('TEMPORARY',name,im.size)

# Ninja jump: ascendant mint wind, keeping the exact Art Team side profile.
im=base('ninja_side_0.png',0,-3);d=ImageDraw.Draw(im)
d.line((3,25,6,27,11,25),fill=T,width=1)
d.line((20,27,27,27),fill=W,width=1)
d.line((5,31,9,31),fill=L,width=1)
save(im,'ninja_jump.png')
# Ninja action: star of a shuriken and bright motion slash.
im=base('ninja_side_0.png',-2,0);d=ImageDraw.Draw(im)
d.line((19,7,28,16),fill=T,width=2)
d.line((25,14,30,14),fill=W,width=1)
d.line((28,12,28,17),fill=W,width=1)
d.point((28,14),fill=L)
d.line((19,19,27,18),fill=L,width=1)
save(im,'ninja_action.png')
# Ninja hurt: pulse on source alpha, not a replacement full-body drawing.
im=base('ninja_front_0.png');film=Image.new('RGBA',im.size,R)
film.putalpha(im.getchannel('A').point(lambda a:int(a*.30)))
im=Image.alpha_composite(im,film)
d=ImageDraw.Draw(im)
d.line((1,8,6,13),fill=R,width=1)
d.line((1,13,6,8),fill=W,width=1)
d.point((27,7),fill=G)
save(im,'ninja_hurt.png')

im=base('wolf_walk_0.png',0,-3);d=ImageDraw.Draw(im)
d.line((3,27,8,29,13,28),fill=L,width=1)
d.line((20,29,27,29),fill=W,width=1)
save(im,'werewolf_jump.png')
im=base('wolf_walk_1.png',-2,0);d=ImageDraw.Draw(im)
for xo in (0,4,8):
    d.line((22+xo,10,18+xo,20),fill=W if xo==4 else R,width=1)
d.line((8,28,13,30),fill=G,width=1)
save(im,'werewolf_action.png')
im=base('wolf_damage_1.png')
overlay=Image.new('RGBA',im.size,(252,128,141,255))
overlay.putalpha(im.getchannel('A').point(lambda a:int(a*.20)))
im=Image.alpha_composite(im,overlay)
d=ImageDraw.Draw(im)
d.line((0,7,5,12),fill=R)
save(im,'werewolf_hurt_fx.png')
