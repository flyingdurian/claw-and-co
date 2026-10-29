#!/usr/bin/env python3
"""Reproducibly stage exact Astra sprite islands and warp decorative fixed depth rails.
This is art preparation only; no generated performance evidence."""
from pathlib import Path
from PIL import Image
import numpy as np, cv2, shutil, json
ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path('/mnt/data')
OUT=ROOT/'art/r5/mechanics';OUT.mkdir(parents=True,exist_ok=True)
assets={}
files=[('gantry/'+p.stem,p) for p in (SOURCE/'claw_r51_gantry_review/parts').glob('*.png')]
files += [('claw/'+p.stem,p) for p in (SOURCE/'claw_r51_component_review/extracted_components').glob('*.png')]
for key,p in files:
    sub,name=key.split('/'); folder=OUT/sub;folder.mkdir(exist_ok=True,parents=True)
    dest=folder/(name+'.png');shutil.copy2(p,dest)
    with Image.open(dest) as im: assets[key]={'file':str(dest.relative_to(ROOT)),'size':im.size}
# original cabinet and recovered interior
base=ROOT/'art/r5';base.mkdir(exist_ok=True)
shutil.copy2(SOURCE/'claw_r51_gantry_review/M01 Raspberry Claw Cabinet Body.png',base/'m01_body.png')
shutil.copy2(SOURCE/'claw_m01_registration_review/M01_intermediate_registered_candidate_NOT_FINAL.png',base/'m01_interior_recovered.png')
Image.open(SOURCE/'claw_r51_asset_review/Machine-free neon arcade aisle.png').convert('RGB').resize((1280,720),Image.Resampling.LANCZOS).save(base/'front_aisle_architecture.png',optimize=True)
# Source texture warped into camera-matched **fixed depth rails**; not primitive placeholder rods.
# Source (2 beams) is long and horizontal in Astra atlas; two planar surfaces projected
# to physically converge toward the rear of the 3/4 cabinet chamber.
canvas=np.zeros((1536,1024,4),dtype=np.uint8)
quads=[[(398,348),(421,347),(327,399),(312,400)],[(705,347),(722,351),(883,404),(862,404)]]
for p,poly in zip([OUT/'gantry/depth_rail_a.png',OUT/'gantry/depth_rail_b.png'],quads):
    src=np.array(Image.open(p).convert('RGBA'))
    h,w=src.shape[:2]
    srcq=np.float32([[0,0],[w-1,0],[w-1,h-1],[0,h-1]])
    dstq=np.float32(poly)
    hom=cv2.getPerspectiveTransform(srcq,dstq)
    # cv2 alpha warp premultiplication avoids bright fragments at transparent margins.
    rgb=src[:,:,:3].astype(np.float32)
    a=src[:,:,3:4].astype(np.float32)/255.0
    rgba=np.concatenate([rgb*a,src[:,:,3:4]],axis=2).astype(np.uint8)
    warped=cv2.warpPerspective(rgba,hom,(1024,1536),flags=cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
    alpha=warped[:,:,3:4].astype(np.float32)
    unpremul=np.where(alpha>0.5,warped[:,:,:3].astype(np.float32)*255.0/np.maximum(alpha,1),0.0)
    warped[:,:,:3]=np.clip(unpremul,0,255).astype('uint8')
    # composite with increasing transparency, use PIL alpha to avoid crossing rails
    canvas=np.array(Image.alpha_composite(Image.fromarray(canvas,'RGBA'),Image.fromarray(warped,'RGBA')))
Image.fromarray(canvas,'RGBA').save(base/'m01_fixed_depth_rails.png',optimize=True)
asset_data={'source_atlas_claw':'Six-Part Chrome Claw Disassembly Atlas.png','source_atlas_gantry':'Exploded Chrome Gantry Hoist Atlas.png','components':assets,'fixed_rails_projection':quads,'registration':'R5.1 experimental fit; not owner acceptance'}
(base/'mechanical_asset_manifest.json').write_text(json.dumps(asset_data,indent=2)+'\n')
print('ART_ASSETS_CREATED',len(files)+4, 'files; fixed rails projected')
