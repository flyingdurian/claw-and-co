#!/usr/bin/env python3
"""Inspect existing V3.1 source alpha/registration BEFORE changing presentation masks.
Production source images are read-only. Outputs belong to CI proof artifacts."""
from pathlib import Path
from PIL import Image, ImageDraw
from collections import OrderedDict
root=Path(__file__).resolve().parents[1]
src=root/'art/m01_v31'
out=root/'ci/output/m01v31/mask_inspection'
out.mkdir(parents=True,exist_ok=True)
names=['M01Cabinet','m01_body','front_posts_mask','front_left_pillar_only_mask','left_pillar_occlusion','roof_fascia_mask','chain_feed_occlusion','center_post_mask','depth_rail_left','depth_rail_right','cable_chain']
for name in names:
 im=Image.open(src/(name+'.png')).convert('RGBA')
 a=im.getchannel('A')
 print('ALPHA',name,'size',im.size,'bbox',a.getbbox(), 'opaque_bbox',a.point(lambda x:255 if x>224 else 0).getbbox())
 if im.size==(1024,1536):
  strips=[(0,110,0,530),(900,1024,0,530),(160,880,290,430),(0,1024,200,600)]
  for x1,x2,y1,y2 in strips:
   region=a.crop((x1,y1,x2,y2))
   hist=region.histogram()
   nonzero=sum(hist[1:]); opaque=sum(hist[225:])
   print(' REGION',name, (x1,x2,y1,y2),'nonzero',nonzero,'opaque',opaque)
  bg=Image.new('RGBA',im.size,(52,59,77,255))
  draw=ImageDraw.Draw(bg)
  for y in range(0,1536,48):
   for x in range(0,1024,48):
    if (x//48+y//48)%2==0:draw.rectangle((x,y,x+47,y+47),fill=(95,103,125,255))
  rendered=Image.alpha_composite(bg,im)
  rendered.thumbnail((480,720))
  rendered.convert('RGB').save(out/(name+'_alpha_check.png'))
print('INSPECT_V31_SOURCE_MASKS_DONE')
