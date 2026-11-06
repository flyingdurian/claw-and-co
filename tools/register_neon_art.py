#!/usr/bin/env python3
"""Measure atlas regions without modifying any artwork bytes."""
import json, hashlib
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art/neon_shift'
layouts={ART/'actor01_identity.png':(1,1)}
layouts.update({p:(1,1) for p in (ART/'walk').glob('*.png')})
layouts.update({ART/'sources'/name:shape for name,shape in {
    'mika_reactions.png':(3,2),'service_props.png':(3,2),'prep_equipment.png':(3,1),
    'ren_poses.png':(4,2),'yuki_poses.png':(4,2)}.items()})
regions={}
for path,(columns,rows) in layouts.items():
    with Image.open(path) as im:
        alpha=im.convert('RGBA').getchannel('A')
        cells=[]
        for i in range(columns*rows):
            x0=int(i%columns*im.width/columns);x1=int((i%columns+1)*im.width/columns)
            y0=int(i//columns*im.height/rows);y1=int((i//columns+1)*im.height/rows)
            # Ignore near-transparent generator residue; retain a 2px edge gutter.
            bounds=alpha.crop((x0,y0,x1,y1)).point(lambda a:255 if a>=32 else 0).getbbox()
            if bounds is None:raise ValueError(f'Empty atlas cell: {path} {i}')
            l,t,r,b=bounds;l=max(0,l-2);t=max(0,t-2);r=min(x1-x0,r+2);b=min(y1-y0,b+2)
            cells.append([x0+l,y0+t,r-l,b-t])
        regions['res://'+str(path.relative_to(ROOT))]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'grid':[columns,rows],'regions':cells}
(ART/'registration.json').write_text(json.dumps(regions,indent=2)+'\n')
print(f'Registered {sum(len(v["regions"]) for v in regions.values())} regions; source PNG bytes unchanged.')
