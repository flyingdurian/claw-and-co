#!/usr/bin/env python3
"""Verify registered source hashes, atlas geometry and preserved Actor 01 identity."""
import hashlib,json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
assert sha(ROOT/'art/neon_shift/actor01_identity.png')=='dfc1312937313976179bf5cb830f088e79134eb9018fce09a468ed1b943e81e3'
manifest=json.loads((ROOT/'art/neon_shift/registration.json').read_text())
count=0
for path,entry in manifest.items():
    local=ROOT/path.removeprefix('res://')
    assert sha(local)==entry['sha256'],f'Source changed: {path}'
    with Image.open(local) as im:
        assert im.mode=='RGBA',path
        assert len(entry['regions'])==entry['grid'][0]*entry['grid'][1]
        for x,y,w,h in entry['regions']:
            assert min(x,y)>=0 and min(w,h)>0 and x+w<=im.width and y+h<=im.height,path
            count+=1
for item in json.loads((ROOT/'art/neon_shift/provenance.json').read_text()):
    assert sha(ROOT/item['path'])==item['sha256'],item['path']
print(f'NEON_ASSET_AUDIT: {len(manifest)} registered sources, {count} bounded regions, canonical Actor 01 SHA preserved')
