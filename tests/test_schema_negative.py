#!/usr/bin/env python3
"""Adversarial JSON Schema checks, not headless Godot runtime tests."""
from pathlib import Path
from jsonschema import Draft202012Validator
import copy,json
R=Path(__file__).resolve().parents[1]
read=lambda p:json.loads((R/p).read_text())
for fname,schema in [('items.stage1.json','items.schema.json'),('machine_types.stage1.json','machine_types.schema.json'),('stage_01.json','stage.schema.json')]:
    doc=read('data/'+fname)
    v=Draft202012Validator(read('schemas/'+schema))
    assert v.is_valid(doc),fname
    bad=copy.deepcopy(doc)
    if fname.startswith('items'):bad['items'][0]['kind']='NOT_AN_ITEM'
    if fname.startswith('machine'):bad['machine_types'][0]['admission_credits']=-3
    if fname.startswith('stage'):bad['duration_ticks']=-1
    assert not v.is_valid(bad),fname
    print('PASS: JSON schema accepts valid',fname,'and rejects invalid mutation')
