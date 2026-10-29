#!/usr/bin/env python3
"""Clearly labeled side-by-side artwork reference vs. *actual Godot* capture.
Does not score near-parity automatically. Purely a visual review aid.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
R=Path(__file__).resolve().parents[1]
OUT=R/'ci/output/comparisons'; OUT.mkdir(parents=True,exist_ok=True)
CASES=[
    ('01_arcade_start.png','approved_living_arcade_full_aisle.png','Arcade initial state'),
    ('03_arcade_activity.png','approved_living_arcade_full_aisle.png','Arcade after scripted gameplay'),
    ('04_workshop.png','approved_gate_e_akihabara_composite.png','Workshop (reference composite includes other views)')
]
for actual, ref, title in CASES:
    p=R/'ci/output/screenshots'/actual
    q=R/'docs/references'/ref
    if not p.is_file() or not q.is_file(): raise SystemExit('Cannot create benchmark comparison: missing genuine screenshot or approved reference')
    with Image.open(p) as im,Image.open(q) as benchmark:
        if im.size!=(1280,720): raise SystemExit(f'Not a 1280x720 native capture: {p}')
        canvas=Image.new('RGB',(2560,790),'#172234')
        canvas.paste(ImageOps.contain(benchmark.convert('RGB'),(1280,720)),(0,70))
        canvas.paste(im.convert('RGB'),(1280,70))
        draw=ImageDraw.Draw(canvas)
        draw.text((28,22),'APPROVED ART BENCHMARK | source illustration',fill='#ffffff')
        draw.text((1310,22),'ACTUAL GODOT RENDER | GL software renderer',fill='#ffffff')
        outfile=OUT/actual.replace('.png','_comparison.png')
        canvas.save(outfile)
        print(f'CREATED labeled review comparison: {outfile.name}')
print('Visual comparison does not certify acceptance or image parity.')
