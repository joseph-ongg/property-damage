"""Deterministic original low-resolution interior; Pillow needed only to rebuild."""
from PIL import Image,ImageDraw
from pathlib import Path
import random,math
D=Path(__file__).resolve().parent
rng=random.Random(1906)
im=Image.new('RGB',(480,270),'#293648')
d=ImageDraw.Draw(im)
def rect(box,c):d.rectangle(box,fill=c)
def line(points,c,w=1):d.line(points,fill=c,width=w)
# small scale: coordinates in half-pixels, upscale NEAREST on save
for y in range(0,249):
 fade=y/250
 d.line((0,y,480,y),fill=(int(43+10*fade),int(52+7*fade),int(67+4*fade)))
# wallpaper fibers, restrained values to avoid distracting from play
for x in range(7,480,27):
 line((x,8,x,248),'#343d4d')
 for y in range(18,245,30):rect((x-1,y,x+1,y+4),'#3c4352')
for y in [6,12,247]:rect((0,y,479,y+2),'#69606a')
# wall art: clock, two small gold-framed pieces
for x,y,w,h in [(58,69,63,43),(352,71,51,46)]:
 rect((x-3,y-3,x+w+3,y+h+3),'#7a5a51')
 rect((x,y,x+w,y+h),'#bb956d')
 rect((x+3,y+3,x+w-3,y+h-3),'#243c4a')
 d.polygon([(x+5,y+h-4),(x+23,y+12),(x+37,y+h-4)],fill='#526970')
 d.polygon([(x+22,y+h-4),(x+39,y+16),(x+w-5,y+h-4)],fill='#49576e')
# hanging clock circular face
cx,cy=319,86
d.ellipse((cx-20,cy-20,cx+20,cy+20),fill='#765a4f')
d.ellipse((cx-17,cy-17,cx+17,cy+17),fill='#d8c59a')
d.ellipse((cx-12,cy-12,cx+12,cy+12),fill='#e7d8ba')
line((cx,cy,cx,cy-9),'#5f4546',2);line((cx,cy,cx+7,cy+4),'#5f4546',2)
# center window with lunar scene
rect((184,36,296,117),'#7d605a')
rect((190,41,290,111),'#16263b')
for y in range(44,111):
 t=(y-44)/67
 line((191,y,289,y),(int(24+10*t),int(40+11*t),int(63+9*t)))
d.ellipse((261,54,277,70),fill='#eee1b5')
for x in range(198,290,12):
 h=13+(x*7)%19
 rect((x,112-h,x+12,111),'#2d4356')
 for j in range(x+3,x+12,5):rect((j,106,j+1,108),'#ab9871')
rect((186,39,190,114),'#c7a47a');rect((290,39,294,114),'#c7a47a')
rect((190,39,290,42),'#c7a47a');rect((190,112,290,115),'#c7a47a')
rect((239,42,242,111),'#c7a47a');rect((191,77,289,80),'#c7a47a')
rect((181,116,299,119),'#e4bd82')
# sunlit domestic floor (characters draw in front)
rect((0,249,480,270),'#76695e')
for x in range(0,480,29):
 line((x,250,x,270),'#645b56')
 for y in (255,265):line((x,y,x+29,y),'#847466')
rect((0,247,479,250),'#c3a880')
# center rug, deliberately beneath feet
rect((181,251,340,268),'#554554')
rect((185,254,336,265),'#7d4b51')
rect((190,257,332,262),'#966e5b')
for x in range(193,334,18):
 d.polygon([(x,259),(x+6,255),(x+12,259),(x+6,263)],fill='#c39771')
# glowing wall sconce; warm light painted pixel rings
for lx,ly in [(139,117),(344,117)]:
 for radius in (21,14,8):
  d.ellipse((lx-radius,ly-radius,lx+radius,ly+radius),outline=['#64594e','#846b56','#bd945f'][[21,14,8].index(radius)])
 rect((lx-3,ly-4,lx+3,ly+8),'#6b514c');rect((lx-2,ly-6,lx+2,ly+4),'#f7c784')
# couch silhouette on left foreground; decorative, not a physical barrier
rect((11,196,64,248),'#4d434f');rect((15,189,62,243),'#72616b')
rect((17,200,61,231),'#8b6667');rect((13,222,65,247),'#9d7775')
rect((13,244,64,249),'#4c3d49')
rect((13,241,16,250),'#b89171');rect((62,241,65,250),'#b89171')
rect((31,219,47,231),'#b4957c')
# shelving aligned to physical bookshelf top y172 (world 344)
rect((72,174,168,249),'#493744')
rect((75,178,164,244),'#765449')
for row,y in enumerate([180,199,220]):
 for i in range(12):
  x=79+i*7
  top=y+(i*3+row)%5
  h=14-(top-y)
  c=['#b79573','#7e9a91','#b16f65','#a3a4a0','#867996'][(i+row)%5]
  rect((x,top,x+4,top+h),c)
  line((x+1,top+2,x+1,top+h-2),'#e1b896')
 rect((76,y+16,164,y+19),'#c09a6c')
rect((72,171,168,175),'#d2a576')
rect((72,171,168,171),'#f1cf97')
# table aligned to physical table collider y205.5 / world 411
rect((186,205,300,213),'#a3775c')
rect((193,213,200,248),'#76524d');rect((288,213,295,248),'#76524d')
rect((187,206,298,208),'#e5ba84')
rect((194,211,294,214),'#634a4b')
# hanging table lamp lighting on upper part of table, no collision
rect((276,192,279,205),'#bba882')
d.polygon([(264,184),(290,184),(283,192),(272,192)],fill='#dac295')
rect((276,181,278,184),'#72554d')
# fridge top world 350/2 =175
rect((358,175,425,249),'#8e9398')
rect((361,178,423,245),'#b9b6b5')
rect((357,175,425,179),'#e2d1b4')
rect((360,208,423,211),'#777f8a')
rect((369,187,371,199),'#5b6470');rect((369,219,371,232),'#5b6470')
# Small magnets reinforce pixel material detail
for x,y,c in [(391,183,'#a96765'),(408,190,'#6e9d9f'),(394,198,'#d3b476')]:rect((x,y,x+4,y+4),c)
# Window curtain edges, in front of distant view
rect((180,38,184,116),'#8e6770');rect((295,38,300,116),'#8e6770')
for y in range(45,117,9):
 rect((180,y,181,y+4),'#ad7d78');rect((298,y,299,y+4),'#ad7d78')
# outer world walls
for x in (0,474):
 rect((x,0,x+6,249),'#65616a')
 rect((x+2,0,x+3,249),'#958078')
# subtle pixel noise (enough texture without scene becoming busy)
for _ in range(1100):
 x=rng.randint(11,468);y=rng.randint(15,244)
 px=im.getpixel((x,y))
 if 40 <= px[0] <= 55:
  n=rng.choice([-4,-3,2,3]);im.putpixel((x,y),tuple(max(0,min(255,c+n)) for c in px))
im=im.resize((960,540),Image.Resampling.NEAREST)
im.save(D/'living_room_pixel.png',optimize=True)
print('Created original living-room pixel artwork', im.size, (D/'living_room_pixel.png').stat().st_size)
