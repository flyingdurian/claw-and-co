#!/usr/bin/env python3
"""Fail closed: a visual milestone cannot pass with missing/unlayered source art."""
from pathlib import Path
from PIL import Image
import json,sys,hashlib
ROOT=Path(__file__).resolve().parents[1]
doc=json.loads((ROOT/'docs/r5/R51_asset_contract.json').read_text())
issues=[]
for item in doc['image_requirements']:
    path=ROOT/item['path']
    if not path.is_file():
        issues.append('Missing authored asset '+str(path.relative_to(ROOT)))
        continue
    try:
        with Image.open(path) as image:
            image.load()
            w,h=image.size
            if w<item['minimum_dimensions'][0] or h<item['minimum_dimensions'][1]:
                issues.append('Insufficient resolution '+str(path.relative_to(ROOT)))
            if item['alpha'] and 'A' not in image.getbands():
                issues.append('Missing alpha layer '+str(path.relative_to(ROOT)))
    except Exception as e: issues.append(str(e))
    # This catches literal copies; crop/collage and semantic fidelity require review.
    if path.is_file():
        h=hashlib.sha256(path.read_bytes()).hexdigest()
        for benchmark in doc['original_approved_benchmarks']:
            bp=ROOT/benchmark
            if bp.is_file() and hashlib.sha256(bp.read_bytes()).hexdigest()==h:
                issues.append('Direct benchmark-copy artwork prohibited '+str(path))
if not (ROOT/doc['godot_review_scene']).exists():
    issues.append('Missing real Godot proof scene')
print('R51_SOURCE_ART_CHECK:', 'BLOCKED' if issues else 'READY_FOR_ENGINE_REVIEW')
for issue in issues: print('R51_BLOCKER:',issue)
print('R51_OWNER_VISUAL_ACCEPTANCE: PENDING (never inferred by static checks)')
if issues: sys.exit(2)
