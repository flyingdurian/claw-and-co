#!/usr/bin/env python3
"""Static GDScript contract check; intentionally not a replacement for Godot runtime tests."""
from pathlib import Path
from collections import Counter
import json, re
root=Path(__file__).resolve().parents[1]
paths=list((root/'scripts').rglob('*.gd'))
assert len(paths)>=12
classes={}
for p in paths:
    src=p.read_text()
    names=re.findall(r'(?m)^class_name\s+(\w+)',src)
    for name in names:
        assert name not in classes,(name,p,classes.get(name))
        classes[name]=str(p.relative_to(root))
    assert 'extends ' in src, p
    assert '\t' not in src, f'tab indentation mixed: {p}'
    assert not re.search(r'assert\(\s*(?:ledger|customers)\.',src),f'assert side effect: {p}'
    assert not re.search(r'\b(?:randf|randi|randomize|await|yield)\s*\(',src),f'non-deterministic/random code: {p}'
for name in ('ItemData','MachineData','StageManifest','SchemaLoader','SimulationClock','InventoryLedger','MachineManager','CustomerManager','WorkshopManager','CartManager','SimulationRoot','SimulationDriver'):
    assert name in classes,name
project=(root/'project.godot').read_text()
assert 'physics_ticks_per_second=60' in project
assert 'renderer/rendering_method="forward_plus"' in project
assert 'viewport_width=1280' in project and 'viewport_height=720' in project
assert not list(root.rglob('*.tscn')), 'Gate E scenes must not be introduced'
assert not list(root.rglob('*.png')), 'Gate E assets must not be introduced'
stage=json.loads((root/'data/stage_01.json').read_text())
assert stage['duration_ticks']==7200
assert stage['cart']=={'supply_slots':4,'prize_slots':2,'bulk_cradle_slots':1}
print(f'PASS: {len(paths)} GDScript files, {len(classes)} unique global classes, explicit 60Hz Forward+ project')
print('PASS: 4+2+1 cart locked; 7200 ticks; no RNG or asynchronous scene timers; no temporary scenes/sprites')
print('NOTE: Static source checks do not parse or execute GDScript')
