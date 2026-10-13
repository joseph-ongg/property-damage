"""Draw original left-facing 3/4 pixel fan in separate depth plates; no AI art."""
from pathlib import Path
from PIL import Image, ImageDraw
from math import radians, sin, cos
D=Path(__file__).parent/'sprites';D.mkdir(parents=True,exist_ok=True)
W,H=48,56
def blank():
 im=Image.new('RGBA',(W,H));return im,ImageDraw.Draw(im)
def ell(d,x,y,rx,ry,**kwargs):d.ellipse((x-rx,y-ry,x+rx,y+ry),**kwargs)
back,d=blank()
ell(d,24,51,16,3,fill=(20,25,39,90))
d.polygon([(11,50),(15,47),(30,47),(36,50),(33,53),(11,53)],fill='#283141')
d.polygon([(12,49),(15,47),(30,47),(34,49)],fill='#a77964')
d.line([(14,48),(29,48)],fill='#efd0a0',width=1)
d.rectangle((25,34,29,48),fill='#354857');d.rectangle((26,35,27,46),fill='#94afb7')
d.polygon([(22,34),(28,32),(31,34),(29,37),(23,37)],fill='#4b6571')
ell(d,25,20,13,16,fill='#293746')
ell(d,25,19,11,14,fill='#849da9')
ell(d,23,20,10,12,fill='#385162')
ell(d,18,20,9,13,fill='#324a57',outline='#1e2d3d')
for x,y in [(17,9),(10,15),(11,26),(18,32),(25,27),(25,13)]:d.line([(18,20),(x,y)],fill='#789aa7')
d.arc((12,4,38,37),-70,65,fill='#e7cfa7',width=2)
d.rectangle((25,46,27,47),fill='#6de0d4')
back.save(D/'rear.png',optimize=True)
for f in range(6):
 im,d=blank();angle=f*20+5
 for arm in range(3):
  a=radians(angle+arm*120);dx,dy=cos(a),sin(a);nx,ny=-dy,dx
  coords=[(18+dx*1.6+nx*1.1,20+dy*1.6+ny*1.1),(18+dx*6+nx*2.5,20+dy*9+ny*2.1),(18+dx*7-nx,20+dy*10-ny),(18+dx*2-nx*2,20+dy*3-ny)]
  d.polygon([(round(x),round(y)) for x,y in coords],fill='#79b4c4')
  d.line([tuple(map(round,coords[0])),tuple(map(round,coords[1]))],fill='#d5e6d7')
 im.save(D/f'blade_{f}.png',optimize=True)
front,d=blank()
ell(d,17,20,10,15,outline='#293849',width=2)
ell(d,17,20,9,14,outline='#d9dbcd')
ell(d,17,20,7,12,outline=(133,173,181,185))
for dx in [-6,-3,0,3,6]:
 h=round(13*(1-(abs(dx)/11)**2)**0.5)
 d.line([(17+dx,20-h),(17+dx,20+h)],fill=(211,224,217,140))
for y,rx in [(12,7),(16,9),(20,10),(24,9),(28,7)]:d.line([(17-rx,y),(17+rx,y)],fill=(198,222,217,120))
d.arc((7,5,27,35),92,262,fill='#f2d9af',width=2)
d.arc((7,5,27,35),-87,78,fill='#3c5161',width=2)
ell(d,18,20,3,3,fill='#283546')
ell(d,18,20,2,2,fill='#ddbc84')
d.point((17,19),fill='#ffeed0')
front.save(D/'front.png',optimize=True)
sheet=Image.new('RGBA',(W*6,H))
for f in range(6):
 im=back.copy();im.alpha_composite(Image.open(D/f'blade_{f}.png'));im.alpha_composite(front)
 sheet.alpha_composite(im,(W*f,0))
sheet.save(D/'preview_sheet.png',optimize=True)
print('GENERATED',len(list(D.glob('*.png'))),'48x56 pixel-art files')
