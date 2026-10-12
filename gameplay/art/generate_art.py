"""Deterministic ORIGINAL pixel-art assets, inspired by atmospheric HD-2D lighting.
Development only: python3 gameplay/art/generate_art.py (requires Pillow).
Runtime does not require Pillow; checked-in PNGs are used directly by Godot.
"""
from PIL import Image, ImageDraw
from math import sin, cos, pi
from pathlib import Path
import random
P=Path(__file__).resolve().parent
R=random.Random(17129)

def rgb(h):return tuple(bytes.fromhex(h.strip('#')))
def save(img,name):
 img.save(P/name,optimize=True)
 print(name,img.size)

def rect(d, xy, col):d.rectangle(xy,fill=rgb(col))
# Deep blue evening, moonlit ruins, side-scrolling silhouette; paint at half res
im=Image.new('RGB',(480,270));d=ImageDraw.Draw(im)
for y in range(270):
 t=y/270
 d.line((0,y,480,y),fill=(int(13+11*t),int(22+18*t),int(43+23*t)))
# luminous crescent, fragmented star field
for _ in range(170):
 x=R.randrange(2,477);y=R.randrange(4,162)
 brightness=R.choice([60,80,108,130,172,205]);col=(int(brightness*.67),int(brightness*.78),brightness)
 d.point((x,y),fill=col)
 if brightness>190: d.line((x-1,y,x+1,y),fill=(75,99,135))
d.ellipse((375,23,407,55),fill=(196,198,165));d.ellipse((383,18,416,51),fill=(20,31,53))
# layered mountain outlines
for z,color in [(0,'23334a'),(1,'2a3c52'),(2,'304253')]:
 pts=[(0,190+z*10)]
 for x in range(0,500,19): pts.append((x,int(165+z*10+sin(x*.018+z)*18+sin(x*.041)*8)))
 pts.extend([(480,275),(0,275)])
 d.polygon(pts,fill=rgb(color))
# village silhouettes and castle skyline with lit gothic windows
for i in range(20):
 x=i*26-7+R.randint(-8,7);h=R.randrange(37,83)
 y=217-h
 color=R.choice(['202d3a','253545','273640'])
 rect(d,(x,y,x+20,221),color)
 d.polygon([(x-3,y),(x+10,y-14),(x+23,y)],fill=rgb('182432'))
 for wy in range(y+12,217,13):
  for wx in [x+5,x+14]:
   if R.random()<.53:rect(d,(wx,wy,wx+2,wy+5),R.choice(['c79d58','bb834b','65756b']))
# distant tall tower near left
rect(d,(45,63,76,209),'253545');rect(d,(50,44,71,73),'253545')
d.polygon([(43,45),(60,19),(78,45)],fill=rgb('202d40'))
for y in [86,107,128,155]:
 d.ellipse((57,y,64,y+9),fill=rgb('b5a269'))
# foreground decorative arches and lanterns, do not cover central action heavily
for x in (5,459):
 rect(d,(x,0,x+15,248),'2d3038');rect(d,(x+2,0,x+5,248),'55505a')
 for y in range(22,237,36):rect(d,(x+6,y,x+11,y+4),'625c62')
rect(d,(0,0,480,4),'3c3946')
# atmosphere haze near floor
fog=Image.new('RGBA',(480,270));fd=ImageDraw.Draw(fog)
for y in range(185,270):
 a=int(45*(y-185)/85)
 fd.line((0,y,480,y),fill=(112,110,99,a))
im=Image.alpha_composite(im.convert('RGBA'),fog)
# nearest: 2px visible pixels for HD-2D-like depth
save(im.resize((960,540),Image.Resampling.NEAREST),'moonlit_ruins.png')

# 32x32 weathered patterned stone with gold seams
im=Image.new('RGBA',(32,32),(0,0,0,0));d=ImageDraw.Draw(im)
rect(d,(0,0,31,31),'323744')
for y in range(0,32,12):
 offs=0 if y%24==0 else 9
 for x in range(-20+offs,40,21):
  rect(d,(x,y,x+19,min(y+10,31)),R.choice(['4e4e52','535058','4a4a55','59535a']))
  d.line((x+2,y+2,x+17,y+2),fill=rgb('70666a'))
  d.line((x+2,y+8,x+17,y+8),fill=rgb('393d48'))
for _ in range(22):
 x=R.randrange(32);y=R.randrange(32)
 d.point((x,y),fill=rgb(R.choice(['77705f','303943','82705a'])))
save(im,'stone_tile.png')

# raised planks with copper rivets and fine highlights
im=Image.new('RGBA',(32,16),(0,0,0,0));d=ImageDraw.Draw(im)
rect(d,(0,0,31,3),'c7a16b');rect(d,(0,4,31,10),'80614d');rect(d,(0,11,31,15),'3b3943')
d.line((0,5,31,5),fill=rgb('bd8859'));d.line((0,13,31,13),fill=rgb('655b59'))
for x in [3,24]:rect(d,(x,7,x+1,8),'c6a56c')
for x in [0,15,31]:d.line((x,5,x,10),fill=rgb('594849'))
save(im,'wood_platform.png')

# MSD co-op mages: readable 32x60 silhouettes that fit the 32x64
# collision box (the sprite is centered 10px above the player origin).
# Original pixel artwork, generated deterministically for easy Art handoff.
for index,p in [(1,{'outline':'172c3f','cloak':'278a91','light':'76dace','shade':'28576d',
                    'trim':'f0d28d','hair':'27374c','cape':'21566b','crystal':'a2fff0'}),
                (2,{'outline':'362a3c','cloak':'bd6153','light':'ffc184','shade':'77415e',
                    'trim':'f2d594','hair':'49324d','cape':'723d55','crystal':'ffe79c'})]:
 im=Image.new('RGBA',(32,60),(0,0,0,0));d=ImageDraw.Draw(im)
 # Back-facing coat tails, a stable triangular silhouette, and separate boots.
 d.polygon([(6,30),(24,30),(28,55),(22,57),(18,54),(13,58),(6,57),(3,53)],fill=rgb(p['outline']))
 d.polygon([(7,32),(25,32),(26,52),(21,54),(15,51),(10,55),(5,52)],fill=rgb(p['cape']))
 rect(d,(8,51,12,57),p['outline']);rect(d,(19,51,24,57),p['outline'])
 rect(d,(9,52,12,54),p['shade']);rect(d,(20,52,23,54),p['shade'])
 rect(d,(7,32,23,48),p['cloak'])
 d.polygon([(7,36),(10,41),(8,50),(5,54),(4,47)],fill=rgb(p['shade']))
 rect(d,(21,35,25,51),p['shade'])
 rect(d,(11,38,13,46),p['light']);rect(d,(19,39,21,46),p['shade'])
 rect(d,(8,45,10,51),p['trim']);rect(d,(18,45,20,50),p['light'])
 # Body, sleeves and a brighter central robe emblem.
 rect(d,(7,29,24,38),p['outline']);rect(d,(8,29,23,35),p['cloak'])
 rect(d,(3,30,8,40),p['outline']);rect(d,(4,31,8,38),p['light'])
 rect(d,(23,30,28,38),p['outline']);rect(d,(23,31,27,37),p['shade'])
 rect(d,(14,34,18,35),p['trim']);rect(d,(15,36,17,40),p['trim'])
 rect(d,(15,42,16,45),p['trim']);rect(d,(14,47,17,49),p['trim'])
 # Neck and face. Two eye pixels help readability at normal scale.
 rect(d,(12,25,19,31),'b88265');rect(d,(11,17,21,28),'e0ac86')
 rect(d,(12,19,19,27),'f0c49a');rect(d,(11,24,12,27),'d59679')
 rect(d,(13,23,14,23),'233245');rect(d,(19,23,20,23),'233245')
 rect(d,(15,27,19,27),'b77867')
 rect(d,(10,17,21,20),p['hair'])
 # Tall, iconic wizard hat; wide brim anchors the head without a big helmet.
 d.polygon([(4,20),(15,1),(22,9),(26,20)],fill=rgb(p['outline']))
 d.polygon([(7,19),(15,3),(20,11),(23,19)],fill=rgb(p['shade']))
 d.polygon([(14,5),(11,14),(14,13),(18,7)],fill=rgb(p['cloak']))
 rect(d,(3,18,27,21),p['outline']);rect(d,(5,18,25,19),p['trim'])
 rect(d,(12,16,20,17),p['trim'])
 rect(d,(15,7,16,10),p['light'])
 # Staff and crystal: a vertical silhouette that immediately reads as a mage.
 rect(d,(28,23,29,51),p['outline'])
 rect(d,(29,24,29,48),'b78661')
 rect(d,(28,20,30,23),p['trim'])
 d.polygon([(29,11),(32-1,16),(29,21),(26,16)],fill=rgb(p['crystal']))
 rect(d,(28,14,29,17),'fff5cb')
 # Small cloak pin / faction jewel.
 rect(d,(15,29,17,31),p['crystal'])
 save(im,f'mage_{index}.png')

# Golden shards, idle/on fire shrine; transparent PNGs
im=Image.new('RGBA',(20,22),(0,0,0,0));d=ImageDraw.Draw(im)
d.polygon([(10,1),(17,9),(12,20),(8,20),(2,9)],fill=rgb('e4b66f'))
d.polygon([(10,2),(14,8),(10,17),(6,9)],fill=rgb('fff0b2'))
d.polygon([(10,2),(17,9),(12,18),(10,17)],fill=rgb('a570ab'))
d.line((10,1,10,17),fill=rgb('fff4cf'))
save(im,'ember_shard.png')
for lit in [False,True]:
 im=Image.new('RGBA',(32,42),(0,0,0,0));d=ImageDraw.Draw(im)
 rect(d,(9,22,22,39),'48404d');rect(d,(7,36,24,40),'73625f')
 rect(d,(11,25,20,34),'6b5758');rect(d,(8,19,23,24),'a78d68')
 rect(d,(6,18,25,20),'debe7c');rect(d,(10,17,21,18),'fff2b0')
 rect(d,(10,8,12,18),'65515a');rect(d,(20,8,22,18),'65515a')
 if lit:
  d.polygon([(12,18),(8,11),(12,4),(15,10),(17,1),(22,12),(19,18)],fill=rgb('f37a3a'))
  d.polygon([(13,18),(12,11),(16,6),(19,15),(17,18)],fill=rgb('ffd276'))
  rect(d,(15,13,16,17),'fff4b3')
 else:
  rect(d,(13,13,18,16),'686572')
 save(im,'brazier_lit.png' if lit else 'brazier_idle.png')

# Radial light canvas; alpha composited by Godot behind lantern/flames
im=Image.new('RGBA',(128,128),(0,0,0,0));pix=im.load()
for y in range(128):
 for x in range(128):
  radius=((x-63.5)**2+(y-63.5)**2)**.5/63.5
  strength=max(0,1-radius)**2.2
  pix[x,y]=(255,180,90,int(strength*105))
save(im,'warm_glow.png')
