#!/usr/bin/env python3
"""Original programmatically drawn pixel art; NO generative model or external art.
Visual-language studies: enchanted travelogue, jewel magic, academy UI.
Art Team sprites remain credited separately and do not get recolored/overwritten.
Run: /usr/bin/python3 gameplay/presentation/generate_assets.py
"""
from __future__ import annotations
import math, random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageEnhance
ROOT = Path(__file__).resolve().parent
O = ROOT / "assets"; O.mkdir(exist_ok=True)
random.seed(1740)
W,H=480,270
NAVY=(15,20,39); INK=(28,34,60); MID=(47,54,91); TEAL=(108,215,209); MINT=(179,250,231); GOLD=(247,205,128); PINK=(244,138,190); LAV=(170,149,230); WHITE=(241,238,245)
FONT="/System/Library/Fonts/Supplemental/Arial Bold.ttf"
if not Path(FONT).exists(): FONT="/System/Library/Fonts/Supplemental/Arial.ttf"
def txt(d,xy,s,size,color=WHITE):
 try: f=ImageFont.truetype(FONT,size)
 except: f=ImageFont.load_default()
 d.text(xy,s,font=f,fill=color,stroke_width=0)
def box(d,b,fill,outline=None,w=1):
 d.rectangle(b,fill=fill,outline=outline,width=w)
def points(d,cx,cy,r,n=8,col=GOLD,shift=0):
 import math
 pts=[(int(cx+math.cos(i*2*math.pi/n+shift)*r),int(cy+math.sin(i*2*math.pi/n+shift)*r)) for i in range(n)]
 d.line(pts+[pts[0]],fill=col,width=1)
def spark(d,x,y,r,c):
 d.line((x-r,y,x+r,y),fill=c)
 d.line((x,y-r,x,y+r),fill=c)
 d.point((x,y),fill=WHITE)
def sky(background='title'):
 im=Image.new("RGB",(W,H)); p=im.load()
 for y in range(H):
  t=y/H
  for x in range(W):
   lumin=math.sin(x/84)*2+math.sin((y+x)/58)*2
   p[x,y]=(int(11+23*t+lumin),int(18+19*t+lumin),int(37+35*t+lumin))
 d=ImageDraw.Draw(im)
 for i in range(150):
  x=random.randrange(W);y=random.randrange(212)
  c=([109,115,167],[187,183,215],[135,221,225])[i%3]
  d.point((x,y),fill=tuple(c))
  if i%23==0:spark(d,x,y,2,tuple(c))
 # moon behind the academy: moody fantasy rather than a copied anime scene.
 d.ellipse((335,12,413,90), fill=(216,216,217))
 d.ellipse((331,8,408,83),fill=(240,230,203))
 d.ellipse((343,14,405,76),fill=(246,238,214))
 for i in range(30):
  x=355+i%6*7;y=29+i//6*8
  if i%7==0:d.point((x,y),fill=(233,224,198))
 # distant city spires / academy rooftops
 for i in range(18):
  x=-10+i*32;hh=(22+(i*37)%54)
  fill=(25,30,57) if i%2 else (29,35,60)
  d.rectangle((x,218-hh,x+30,251),fill=fill)
  d.polygon([(x-4,218-hh),(x+15,198-hh),(x+33,218-hh)],fill=fill)
  if i%4==0:
   d.line([(x+15,182-hh),(x+15,202-hh)],fill=(41,45,79),width=2)
  for j in range(3):
   d.rectangle((x+5+j*8,225-hh,x+7+j*8,229-hh),fill=GOLD)
 d.rectangle((0,241,W,270),fill=(16,23,42))
 d.line((0,241,W,241),fill=GOLD,width=1)
 # painterly atmospheric horizontal runes
 for i in range(13):
  x=8+i*37; y=251+(i%2)*4
  d.line((x,y,x+16,y),fill=(64,74,107))
 return im,d
def save(im,name):
 im.resize((W*2,H*2),Image.Resampling.NEAREST).save(O/name,optimize=True)
def gradient_frame(d,x0,y0,x1,y1):
 for idx in range(4):
  col=(61+idx*9,71+idx*12,113+idx*15)
  d.rectangle((x0+idx,y0+idx,x1-idx,y1-idx),outline=col)
 # deco corners
 for x in [x0+7,x1-7]:
  for y in [y0+7,y1-7]:
   spark(d,x,y,2,GOLD)
im,d=sky()
# central grand arch silhouette and glowing portal, decorative not an interactable object
d.polygon([(185,231),(185,88),(190,65),(201,48),(238,30),(276,48),(288,65),(294,88),(294,231)],fill=(41,42,75))
d.polygon([(199,233),(199,102),(206,82),(220,68),(240,58),(259,68),(274,84),(282,102),(282,233)],fill=(75,62,109))
d.polygon([(209,233),(209,107),(217,91),(229,84),(240,78),(253,86),(264,96),(271,110),(271,233)],fill=(84,91,136))
for r in (39,54,68):
 points(d,240,151,r,12,LAV,shift=math.pi/12)
points(d,240,151,50,6,GOLD,shift=math.pi/6)
spark(d,240,151,15,WHITE)
for x in range(17,465,31):
 d.line((x,236,x+13,236),fill=(127,137,174))
save(im,'title_backdrop.png')
im,d=sky()
gradient_frame(d,10,21,468,243)
# column halos
for cx,c in [(110,TEAL),(367,PINK)]:
 for rad in [42,49,57]:
  points(d,cx,116,rad,12,c,shift=0.04)
 d.ellipse((cx-35,81,cx+35,151),outline=GOLD,width=1)
 d.line((cx-52,190,cx+52,190),fill=c,width=2)
save(im,'lobby_backdrop.png')
im,d=sky()
for i in range(4):
 points(d,240,126,44+i*15,12,[LAV,GOLD,PINK,TEAL][i],shift=0.08)
d.ellipse((196,82,284,170),outline=WHITE,width=1)
spark(d,240,126,31,WHITE)
save(im,'result_backdrop.png')
im,d=sky()
gradient_frame(d,13,22,465,245)
save(im,'help_backdrop.png')
# Original desktop/game icon, transparent 64x64 with arcane moon/star pair.
app_icon=Image.new('RGBA',(64,64),(17,22,41,255))
ic=ImageDraw.Draw(app_icon)
ic.rounded_rectangle((3,3,60,60),radius=8,outline=(*GOLD,255),width=3)
ic.ellipse((13,12,52,51),fill=(*LAV,255))
ic.ellipse((18,9,56,45),fill=(17,22,41,255))
for rr in [16,21]:
    points(ic,32,34,rr,8,(*TEAL,255),shift=.2)
spark(ic,32,34,11,(*WHITE,255))
ic.line((13,52,51,52),fill=(*PINK,255),width=2)
app_icon.save(O/'app_icon.png')

# icon atlas: 16x16 hand coded pixels, gold / teal accents.
atlas=Image.new('RGBA',(16*6,16),(0,0,0,0));q=ImageDraw.Draw(atlas)
symbols=['star','shield','fire','sword','moon','rose']
for i,kind in enumerate(symbols):
 cx=i*16+8;cy=8
 if kind=='star':
  q.line((cx-5,cy,cx+5,cy),fill=GOLD,width=2);q.line((cx,cy-6,cx,cy+6),fill=GOLD,width=2)
  q.rectangle((cx-2,cy-2,cx+2,cy+2),fill=WHITE)
 elif kind=='shield':
  q.polygon([(cx,cy-6),(cx+5,cy-3),(cx+4,cy+4),(cx,cy+7),(cx-4,cy+4),(cx-5,cy-3)],fill=TEAL,outline=WHITE)
 elif kind=='fire':
  q.polygon([(cx,cy-7),(cx+2,cy-2),(cx+5,cy+2),(cx+2,cy+6),(cx-3,cy+6),(cx-5,cy+3),(cx-2,cy-3)],fill=PINK)
  q.polygon([(cx,cy-2),(cx+2,cy+4),(cx-2,cy+4)],fill=GOLD)
 elif kind=='sword':
  q.line((cx-5,cy+5,cx+5,cy-5),fill=WHITE,width=2);q.line((cx-3,cy+2,cx,cy+5),fill=TEAL,width=2)
 elif kind=='moon':
  q.ellipse((cx-5,cy-5,cx+5,cy+5),fill=GOLD);q.ellipse((cx-2,cy-7,cx+7,cy+2),fill=(0,0,0,0))
 else:
  for a in range(5):q.ellipse((cx-5+a%3*3,cy-3+a//3*4,cx-2+a%3*3,cy+a//3*4),fill=PINK)
  q.rectangle((cx,cy+2,cx+1,cy+6),fill=TEAL)
atlas.save(O/'rune_icons.png')
# portraits: original frame sources are from Art Team, locally composited with
# our programmatic ornaments, no external derivative art.
sprites={'mage':'mage_idle_0.png','ninja':'ninja_front_0.png','werewolf':'wolf_walk_0.png'}
E=ROOT.parent/'art_team'/'exported'
for kind,src in sprites.items():
 pic=Image.new('RGBA',(96,116),(0,0,0,0));d=ImageDraw.Draw(pic)
 col={'mage':LAV,'ninja':TEAL,'werewolf':PINK}[kind]
 d.rectangle((0,0,95,115),fill=(25,30,54,255),outline=(*GOLD,255),width=2)
 for rad in [27,31,38]:
  points(d,48,51,rad,10,col,shift=0.12)
 d.rectangle((6,90,89,108),fill=(45,49,80,255),outline=(*col,255))
 with Image.open(E/src) as im0:
  fg=im0.convert('RGBA')
 # center each 32x32 sprite with nearest upscale; used as original art only.
 fw,fh=fg.size;scale=max(2,min(3,76//max(fw,fh)))
 fg=fg.resize((fw*scale,fh*scale),Image.Resampling.NEAREST)
 pic.alpha_composite(fg,((96-fg.width)//2,51-fg.height//2))
 label={'mage':'ARCANIST','ninja':'SHADOW','werewolf':'BEAST'}[kind]
 txt(d,(11,94),label,10,WHITE)
 pic.resize((192,232),Image.Resampling.NEAREST).save(O/f'portrait_{kind}.png')
# map cards: use existing project-owned scene art with decorative original frame
for kind,src in [('living','living_room_map.png'),('garden','garden.png')]:
 p=Image.new('RGBA',(192,122),(18,24,43,255))
 with Image.open(E/src) as im0:
  fg=im0.convert('RGB');fg.thumbnail((176,94),Image.Resampling.NEAREST)
  fg=fg.resize((176,94),Image.Resampling.NEAREST)
  p.paste(fg,(8,8))
 d=ImageDraw.Draw(p)
 for b in range(4):d.rectangle((b,b,191-b,121-b),outline=GOLD if b%2 else LAV,width=1)
 d.rectangle((8,103,183,117),fill=(32,37,66))
 txt(d,(15,103),'THE LIVING ROOM' if kind=='living' else 'THE ROSE GARDEN',10,GOLD)
 p.resize((384,244),Image.Resampling.NEAREST).save(O/f'map_{kind}.png')
# Original 64px enchanted star-circle cast frames. Four angles frame-by-frame
# drawn by PIL, not transformed from any copyrighted magic-symbol artwork.
for phase in range(4):
    sigil=Image.new('RGBA',(64,64),(0,0,0,0));ds=ImageDraw.Draw(sigil)
    hue=[LAV,TEAL,PINK,GOLD][phase]
    cx=32;cy=32
    for radius,n in ((22,12),(25,12),(29,16)):
        pts=[(round(cx+math.cos(i*math.tau/n+phase*.09)*radius),
              round(cy+math.sin(i*math.tau/n+phase*.09)*radius)) for i in range(n)]
        ds.line(pts+[pts[0]],fill=(*hue,190),width=1)
    for n in range(8):
        a=n*math.tau/8+phase*.13
        x=round(cx+math.cos(a)*26);y=round(cy+math.sin(a)*26)
        ds.rectangle((x-1,y-1,x+1,y+1),fill=(*GOLD,235))
    star_points=[]
    for i in range(5):
        a=-math.pi/2+i*math.tau*2/5+phase*.17
        star_points.append((cx+math.cos(a)*14,cy+math.sin(a)*14))
    ds.line(star_points+[star_points[0]],fill=(*WHITE,200),width=1)
    spark(ds,32,32,4,(*GOLD,255))
    sigil.save(O/f'spell_sigil_{phase}.png',optimize=True)

print('generated art',*[f.name for f in sorted(O.iterdir())],sep='\n - ')
