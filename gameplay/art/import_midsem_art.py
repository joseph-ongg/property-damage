"""Import *actual* art from the team's MidSem deck into the Godot prototype.

This is not generative AI. It extracts the Character design PNG/GIF and Art
Team collage on slides 13/12, downsamples with nearest-neighbor, and recolors
only blue costume pixels to red for Player 2. Run manually if the PPT changes.
Checked-in PNG outputs do not require Python or the PPT at Godot runtime.
"""
from pathlib import Path
from io import BytesIO
from PIL import Image
from colorsys import rgb_to_hsv, hsv_to_rgb
from pptx import Presentation

ROOT=Path(__file__).resolve().parents[2]
DECK=Path('/Users/suwen/Downloads/Property Damage MidSem Presentation (1).pptx')
ASSET=ROOT/'gameplay/art'
SCENE_ASSET=ROOT/'gameplay/msd/art'
P=Presentation(str(DECK))

def slide_image(slide, which):
    return Image.open(BytesIO([s.image.blob for s in P.slides[slide].shapes if s.shape_type==13][which]))

static=slide_image(12,0).convert('RGBA')
run_gif=slide_image(12,2)
assert static.size==(736,736) and run_gif.n_frames==2
bbox=(69,0,575,736)

def shrink(mage):
    return mage.crop(bbox).resize((40,60),Image.Resampling.NEAREST)

def to_red(src):
    img=src.convert('RGBA')
    out=Image.new('RGBA',img.size,(0,0,0,0))
    for y in range(img.height):
        for x in range(img.width):
            r,g,b,a=img.getpixel((x,y))
            if a==0:
                continue
            h,s,v=rgb_to_hsv(r/255,g/255,b/255)
            # Recolor blue robe/hat/highlights, not the yellow eyes or black outlines.
            if .51<=h<=.76 and s>.21 and b>=max(r,g)*.99:
                nr,ng,nb=hsv_to_rgb(0.0,min(.95,s*.98),v)
                out.putpixel((x,y),(round(nr*255),round(ng*255),round(nb*255),a))
            else:
                out.putpixel((x,y),(r,g,b,a))
    return out

for idx,transform in [(1,lambda im:im),(2,to_red)]:
    transform(shrink(static)).save(ASSET/f'mage_{idx}.png',optimize=True)
    for frame in range(2):
        run_gif.seek(frame)
        transform(shrink(run_gif.convert('RGBA'))).save(ASSET/f'mage_{idx}_run_{frame}.png',optimize=True)

# Extract component sprites from the actual Art Subteam furniture collage.
collage=slide_image(11,0).convert('RGBA')
assert collage.size==(529,384)
regions={
    'team_shelf':(0,154,178,384),
    'team_ac':(168,0,400,70),
    'team_monitor':(234,183,359,281),
    'team_fridge':(358,202,464,384),
    'team_window':(0,0,134,103),
    'team_clock':(446,0,529,83),
}
for name,rect in regions.items():
    image=collage.crop(rect)
    image.save(SCENE_ASSET/f'{name}.png',optimize=True)

print('Imported PPT art: 2 idle images + 4 run frames + 6 map/furniture crops')
print('PPT Character design: blue wizard, yellow eyes; P2 robe recolored crimson')
