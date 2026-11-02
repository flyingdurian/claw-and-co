#!/usr/bin/env python3
"""ART-02 strict asset registration, not an approval or an art synthesizer.

Validates the exact approved source; requires artist-reconstructed PNG
components with local pivots, neutral-placement coordinates and overlap,
then renders a neutral raster preview WITHOUT hiding missing assets.
Never converts the rejected 128px SVGs into production art.
"""
from __future__ import annotations
import argparse, hashlib, json, sys
from pathlib import Path
from PIL import Image, ImageChops
import numpy as np

EXPECTED='dfc1312937313976179bf5cb830f088e79134eb9018fce09a468ed1b943e81e3'
def run(repo: Path, out: Path)->int:
    manifest_path=repo/'docs/art/actor01_art02_registration.json'
    data=json.loads(manifest_path.read_text(encoding='utf-8'))
    issues=[]
    src=repo/data['approved_master']['path']
    if not src.is_file(): issues.append('APPROVED_MASTER_ABSENT_IN_REPO')
    else:
        raw=src.read_bytes()
        digest=hashlib.sha256(raw).hexdigest()
        if digest!=EXPECTED: issues.append('APPROVED_MASTER_SHA256_MISMATCH')
        with Image.open(src) as original:
            if original.format!='PNG' or original.mode!='RGBA' or original.size!=(1024,1536):
                issues.append('APPROVED_MASTER_FORMAT_OR_DIMENSIONS_CHANGED')
    layer_dir=repo/data['layer_image_dir']
    names=set()
    present=[]
    neutral=[]
    for layer in data['exports']:
        n=layer['name']
        if n in names:issues.append('DUPLICATE_LAYER:'+n)
        names.add(n)
        path=layer_dir/layer['filename']
        if not path.is_file():
            issues.append('MISSING_RECONSTRUCTED_LAYER:'+n)
            continue
        with Image.open(path) as im:
            if im.format!='PNG' or im.mode!='RGBA':
                issues.append('NOT_LOSSLESS_RGBA:'+n); continue
            if im.width<20 or im.height<20:
                issues.append('LOW_RES_LAYER:'+n)
            alpha=im.getchannel('A')
            if not alpha.getbbox(): issues.append('EMPTY_LAYER:'+n)
            if alpha.getextrema()[0]>0:issues.append('NO_TRANSPARENT_BORDER:'+n)
            if layer['neutral_bbox'] is None or layer['neutral_position'] is None or layer['pivot_local'] is None:
                issues.append('UNREGISTERED_NEUTRAL_PLACEMENT:'+n)
            else:
                q=layer['neutral_position']
                if not (isinstance(q,list) and len(q)==2):
                    issues.append('BAD_PLACEMENT:'+n)
                else:
                    neutral.append((int(layer['z_order']),im.copy(),(int(q[0]),int(q[1])),n))
            present.append(n)
    # The composed neutral is evidence only after every unique source
    # artwork component is present and has a registered transform.
    can_composite=not issues and len(neutral)==len(data['exports'])
    metrics={}
    if can_composite:
        with Image.open(src) as original:
            ref=original.convert('RGBA')
        result=Image.new('RGBA',ref.size,(0,0,0,0))
        for z,layer,pos,n in sorted(neutral,key=lambda e:e[0]):
            result.alpha_composite(layer,pos)
        out.mkdir(parents=True,exist_ok=True)
        result.save(out/'actor01_neutral_assembled_raster_PREVIEW.png')
        ref_a=np.array(ref.getchannel('A')).astype(np.float32)
        asm_a=np.array(result.getchannel('A')).astype(np.float32)
        mask_union=(ref_a>8)|(asm_a>8)
        mae=float(np.abs(ref_a-asm_a)[mask_union].mean()) if mask_union.any() else 255.0
        diff=ImageChops.difference(ref,result)
        metrics={'alpha_mae':mae,'pixel_bbox_difference':diff.getbbox(),
           'neutral_image':'actor01_neutral_assembled_raster_PREVIEW.png'}
        if mae>12:issues.append('NEUTRAL_ALPHA_SILHOUETTE_MISMATCH')
    out.mkdir(parents=True,exist_ok=True)
    report={'stage':'ART-02','source_sha256':EXPECTED,'owner_art02_approval':'PENDING',
        'total_required_layers':len(data['exports']),'present_layers':len(present),
        'missing_count':len(data['exports'])-len(present),'issues':issues,
        'neutral_metrics':metrics,'status':'ART_PENDING' if issues else 'TECHNICAL_READY_ART_PENDING',
        'note':'Technical checks cannot approve illustrated fidelity, reconstructed hidden anatomy, joint seams, or Godot pose extremes.'}
    (out/'actor01_art02_validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2))
    return 0 if not issues else 1
if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--repo-root',type=Path,default=Path('.'))
    p.add_argument('--out',type=Path,default=Path('ci/output/r4a-art02'))
    args=p.parse_args()
    sys.exit(run(args.repo_root,args.out))
