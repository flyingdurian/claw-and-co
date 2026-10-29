#!/usr/bin/env python3
"""R5.1 art preflight. Exits 2 on blocked proof in --strict mode.
Never substitutes legacy collage assets for missing real art.
Semantic artistic fidelity still requires human review.
"""
import json,sys
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
m=json.loads((ROOT/'docs/r5/R51_asset_contract.json').read_text())
issues=[]
def issue(msg): issues.append(msg);print('R51_BLOCKER:',msg)
for item in m['image_requirements']:
    file=ROOT/item['path']
    if not file.is_file():
        issue('missing independently authored image '+item['path'])
        continue
    try:
        with Image.open(file) as image:
            image.load()
            w,h=image.size; a='A' in image.getbands()
            minimum=item['minimum_dimensions']
            if w<minimum[0] or h<minimum[1]:
                issue(f'{item["path"]} too small: {w}x{h} expected >= {minimum}')
            if item['alpha'] and not a:
                issue(f'{item["path"]} missing alpha channel')
            if not item['alpha'] and a and image.getextrema()[-1][0]<255:
                issue(f'{item["path"]} environment has unintended transparency')
    except Exception as exc:issue(f'{item["path"]} unreadable: {exc}')
scene=ROOT/m['godot_review_scene']
if not scene.is_file():issue('missing isolated Godot proof scene '+m['godot_review_scene'])
else:
    s=scene.read_text()
    for bad in ('art/parity/arcade_backdrop','art/living/arcade_depth_bg','art/parity/cabinet','ColorRect','Polygon2D'):
        if bad in s: issue(f'proof scene depends on rejected collage/primitive source: {bad}')
for script in ('scripts/core/SimulationRoot.gd','scripts/managers/MachineManager.gd'):
    if not (ROOT/script).is_file():issue('frozen gameplay source missing: '+script)
status='BLOCKED' if issues else 'READY_FOR_ENGINE_AND_OWNER_VISUAL_REVIEW'
print(f'R51_ART_GATE={status}; blockers={len(issues)}')
if '--strict' in sys.argv and issues:sys.exit(2)
