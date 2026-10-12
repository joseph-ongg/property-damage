"""Deterministic nearest-neighbor pixel fireball frames for Godot projectiles."""
from PIL import Image,ImageDraw
from pathlib import Path
from math import sin
out=Path(__file__).resolve().parent
for i in range(6):
    im=Image.new('RGBA',(24,16),(0,0,0,0));d=ImageDraw.Draw(im)
    shift=i%3
    # Single-pixel hard-edged comet and sparks, not blurry glow materials.
    d.polygon([(0,8),(5,5-shift%2),(8,7),(12,3),(18,4),(23,7),
               (20,11),(13,12),(9,10),(5,12)],fill='#b72c18')
    d.polygon([(3,8),(10,6),(15,4),(21,6),(22,8),(20,10),
               (14,11),(10,9)],fill='#ed5c17')
    d.polygon([(7,8),(13,5),(19,6),(22,8),(19,10),(13,10)],fill='#ffa927')
    d.rectangle((15,6,20,9),fill='#ffe879')
    d.rectangle((17,7,19,8),fill='#fff4cc')
    for x,y in [(i%5,3),(5+(i*3)%5,13),(2,7),(12,1+i%2)]:
        d.rectangle((x,y,x+1,y),fill='#ed651b')
    im.save(out/f'fireball_{i}.png',optimize=True)
print('Generated 6 sharp RGBA pixel fireball textures')
