#!/usr/bin/env python3
"""Preflight only, not a substitute for executing Godot GDScript."""
from pathlib import Path
from collections import Counter
import json
R=Path(__file__).resolve().parents[1]
read=lambda n:json.loads((R/'data'/n).read_text())
s=read('stage_01.json'); cmds=read('commands.stage1.json')['commands']
assert len(cmds)>=20
assert [c['tick'] for c in cmds]==sorted(c['tick'] for c in cmds)
ids=[c['command_id'] for c in cmds]
assert len(ids)==len(set(ids))
assert all(0<=c['tick']<s['duration_ticks'] for c in cmds)
assert [s1['session_id'] for s1 in s['sessions']]==['S01','S02','S03','S04','S05']
assert Counter(a['action'] for a in cmds)['purchase_card']==6
assert Counter(a['action'] for a in cmds)['admit_session']==5
assert Counter(a['action'] for a in cmds)['start_production']==4
assert Counter(a['action'] for a in cmds)['staff_key']==1
assert Counter(a['action'] for a in cmds)['restock']==1
assert Counter(a['action'] for a in cmds)['gift_wrap']==1
assert Counter(a['action'] for a in cmds)['trade_up']==1
visits={v['visit_id']:v for wave in s['waves'] for v in wave['visits']}
for c in cmds:
    v=visits.get(c['payload'].get('visit_id'))
    if v: assert c['tick']>=v['arrival_tick']
expected=sum(next(o['price_minor'] for o in s['offers'] if o['offer_id']==step['offer_id']) for v in visits.values() for step in v['steps'] if step['action']=='purchase_card')
assert expected==2700
assert all(j['available_tick']<=next(c['tick'] for c in cmds if c['action']=='start_production' and c['payload']['job_id']==j['job_id']) for j in s['production_jobs'])
print('PASS: Input replay schedule sorted, unique command IDs, 7200-tick bounds')
print('PASS: Five admissions, six card sales, four production jobs, reset, restock, trade-up, wrap all authored')
print('PASS: No pre-arrival interaction; manifest-only projected revenue CAD 27.00')
print('NOTE: Godot 4.7.2 replay script is not executed by this Python preflight')
