#!/usr/bin/env python3
"""Original 480x270 programmatic pixel-art Clocktower Observatory stage.
No image-gen, no source Art Team pixels are overwritten. Reproducible Pillow.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import math,random
HERE=Path(__file__).resolve().parent
OUT=HERE/'observatory_background.png'
random.seed(20261115)
W,H=480,270
im=Image.new('RGB',(W,H));d=ImageDraw.Draw(im)
for y in range(H):
    t=y/(H-1)
    d.line((0,y,W,y), fill=(int(13+17*t),int(17+22*t),int(42+34*t)))
for i in range(280):
    x=random.randrange(W);y=random.randrange(226)
    c=(240,210,160) if i%11==0 else (135,146,209)
    d.point((x,y),fill=c)
    if i%22==0:
        d.point((x+1,y),fill=(81,109,162))
# moon + silver halo
for r in range(37,22,-2):
    d.ellipse((364-r,42-r,364+r,42+r),outline=(40+(37-r)*3,56+(37-r)*3,103+(37-r)*2))
d.ellipse((340,19,387,66),fill=(242,221,185),outline=(173,181,206))
d.ellipse((348,19,387,59),fill=(247,235,205))
d.ellipse((352,29,358,34),fill=(229,217,185))
d.ellipse((374,41,379,45),fill=(225,209,182))
# distant city and spires
for x,h,w in [(5,83,30),(41,115,23),(76,91,32),(123,128,20),(166,88,28),
              (208,105,26),(258,110,29),(310,91,32),(400,122,27),(448,94,31)]:
    d.rectangle((x,225-h,x+w,242),fill=(32,39,74))
    d.polygon(((x,225-h),(x+w//2,225-h-19),(x+w,225-h)),fill=(43,46,84))
    for yy in range(230-h,226,18):
        for xx in range(x+7,x+w-1,11):
            d.rectangle((xx,yy,xx+3,yy+5),fill=(135,114,123) if (xx+yy)%3 else (239,192,127))
# huge arcane clock rising behind the platform
cx,cy=244,151
for r,c in [(85,(85,87,129)),(79,(168,153,173)),(73,(56,69,119)),(67,(141,133,174))]:
    d.arc((cx-r,cy-r,cx+r,cy+r), 0,360,fill=c,width=3)
for a in range(0,360,30):
    an=math.radians(a)
    for r in [72,80]:
        x=cx+math.cos(an)*r;y=cy+math.sin(an)*r
        d.rectangle((int(x)-1,int(y)-1,int(x)+1,int(y)+1),fill=(246,196,137))
d.line((cx,cy,cx+22,cy-24),fill=(240,223,168),width=3)
d.line((cx,cy,cx-18,cy-8),fill=(233,154,164),width=2)
d.ellipse((cx-5,cy-5,cx+5,cy+5),fill=(245,218,154))
# balustrade and balcony supports
d.rectangle((0,231,479,269),fill=(48,44,84))
d.rectangle((0,233,479,240),fill=(137,104,128))
d.line((0,232,480,232),fill=(244,192,131),width=2)
for x in range(3,W,19):
    d.rectangle((x,239,x+5,266),fill=(77,70,108))
    d.line((x+2,239,x+2,264),fill=(117,97,124))
for y in [254,261,269]:
    d.line((0,y,W,y),fill=(91,82,115),width=2)
for x in range(0,480,24):
    d.line((x,247,x,269),fill=(41,48,86),width=2)
# art structures matching physical one-way platforms: at 175/196, 270/230 etc.
for x,y,width in [(54,191,115),(185,158,111),(320,191,115),(192,117,96)]:
    d.rectangle((x,y,x+width,y+6),fill=(124,105,140),outline=(247,195,130))
    d.rectangle((x+8,y+7,x+width-8,y+11),fill=(63,59,112))
    for u in range(x+8,x+width-5,12):
        d.rectangle((u,y+1,u+4,y+2),fill=(204,183,170))
# patterned gemstones, stage skyline
for x,y in [(21,214),(448,214)]:
    d.polygon(((x,y-17),(x+10,y-7),(x+8,y+8),(x-6,y+8),(x-9,y-7)),fill=(98,189,196),outline=(240,219,177))
    d.line((x,y-17,x,y+8),fill=(220,249,241))
# foreground etched spell glyphs
for i in range(5):
    x=70+i*80
    d.arc((x-15,244,x+15,258),0,180,fill=(176,139,170))
# intentional integer 2x pixel scale
im.resize((960,540),Image.Resampling.NEAREST).save(OUT,optimize=True)
print('generated',OUT,'960x540',OUT.stat().st_size,'bytes')
