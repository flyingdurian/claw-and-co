#!/usr/bin/env python3
"""Structural and content checks only. Not a Godot runtime test."""
from pathlib import Path
import json,re,sys,zipfile,hashlib
from PIL import Image
from jsonschema import Draft202012Validator
P=Path(__file__).resolve().parent.parent
checks=[]
def check(test,label):
 checks.append((bool(test),label))
 if not test: print('FAIL:',label)
all_scenes=list((P/'scenes').rglob('*.tscn'))
check(len(all_scenes)>=9,'9+ authored TSCN files')
for f in all_scenes:
 text=f.read_text()
 check('ColorRect' not in text and 'Polygon2D' not in text, f'{f.name}: no placeholder ColorRect or Polygon2D')
 for typ,path in re.findall(r'\[ext_resource type="([^"]+)" path="(res://[^"]+)"',text):
  check((P/path.replace('res://','')).is_file(), f'{f.name}: {path}')
 for m in re.finditer(r'\[node name="([^"]+)"(?:[^\]]*)parent="([^"]+)"',text):
  name,parent=m.groups()
  if parent == '.': continue
  # ensure each parent path exists earlier in same document; instance children not covered here
  parents=[z.group(1) for z in re.finditer(r'\[node name="([^"]+)"[^\]]+parent="\."',text)]
  # explicit parent check by node declaration reconstruction
  nodepaths=set(['.'])
  for n in re.finditer(r'\[node name="([^"]+)"[^\]]*parent="([^"]+)"',text):
   nm,pa=n.groups()
   nodepaths.add(nm if pa=='.' else pa+'/'+nm)
  check(parent in nodepaths, f'{f.name}: parent path {parent}')
for f in [P/'scenes/ArcadeAisle.tscn',P/'scenes/BackstageWorkshop.tscn']:
 check('Sprite2D' in f.read_text(), f'{f.name}: Sprite2D physical art')
s=(P/'scenes/Main.tscn').read_text()
check('type="CanvasLayer"' in s and 'ServiceCartUI" parent="CartCanvas"' in s,'cart remains CanvasLayer across areas')
check('WorldEnvironment' in s, 'WorldEnvironment allocated')
check('position = Vector2(0, 512)' in s,'cart dock correct 1280x720 placement')
s=(P/'scripts/managers/CartManager.gd').read_text()
for slot in [*[f'supply_{i}' for i in range(4)],*[f'gift_{i}' for i in range(2)],*[f'ribbon_{i}' for i in range(2)],'prize_0','prize_1','bulk_0']:
 check(slot in s,slot+' present in authoritative CartManager')
 check(f'[node name="{slot}" type="Control"' in (P/'scenes/ServiceCartUI.tscn').read_text(),slot+' scene node')
check('[node name="staff_key"' in (P/'scenes/ServiceCartUI.tscn').read_text(),'Staff Key permanently available')
check('cart_slot_selected.emit(slot)' in (P/'scripts/presentation/ServiceCartUI.gd').read_text(),'discrete slot signal')
check('selected_cart_slot' in (P/'scripts/presentation/GamePresentation.gd').read_text(),'tap-then-target presentation flow')
check('"cart_slot"' in (P/'scripts/core/SimulationRoot.gd').read_text(),'atomic selected physical IC card purchase')
check('draw_circle(' not in (P/'scripts/presentation/MachineView.gd').read_text(),'mechanism is sprite-driven not _draw primitives')
check('class_name PresentationBridge' in (P/'scripts/presentation/PresentationBridge.gd').read_text(),'gateway preserved')
check('tick' in (P/'scripts/presentation/MachineView.gd').read_text(),'animation derives from simulation ticks')
for mid in ['M01','M02','M03','M04']:
 f=P/'scenes/machines'/f'{mid}_Machine.tscn';t=f.read_text()
 for node in ['BaseBody','PrizeInterior','Mechanism','SpecularGlassOverlay','NeonMarquee','GlowLight']:
  check(f'[node name="{node}"' in t,mid+' '+node)
 for name in ['base','prize_interiors','mechanism','glass_reflection','marquee']:
  check((P/'art/parity/cabinet'/mid/(name+'.png')).is_file(),mid+' '+name+'.png')
for f in [P/'data/stage_01.json', P/'data/items.stage1.json',P/'data/machine_types.stage1.json']:
 json.loads(f.read_text());check(True,'JSON parse '+f.name)
for schema_file,data_file in [('stage.schema.json','stage_01.json'),('items.schema.json','items.stage1.json'),('machine_types.schema.json','machine_types.stage1.json')]:
 try:
  schema=json.loads((P/'schemas'/schema_file).read_text()); data=json.loads((P/'data'/data_file).read_text())
  Draft202012Validator(schema).validate(data)
  check(True,schema_file+' validates '+data_file)
 except Exception as e:check(False,schema_file+': '+str(e))
for name in ['arcade_backdrop','workshop_backdrop','hud_plate']:
 im=Image.open(P/'art/parity'/(name+'.png'));check(im.width>=900 and im.height>=60,name+' authentic high-res art')
for name in ['cart_shell','staff_key']:
 im=Image.open(P/'art/parity/cart'/(name+'.png'));check(im.width>=90,name+' sprite')
check(Image.open(P/'art/parity/arcade_backdrop.png').size==(1280,720),'arcade texture exactly 1280x720')
check(Image.open(P/'previews/gate_e_refactor_offline_arcade.png').size==(1280,720),'offline mock output 1280x720')
# comparison against old source: simulation managers not explicitly changed remain unchanged
orig=Path('/mnt/data/claw_and_co_gate_e_illustrated_godot472_source.zip')
with zipfile.ZipFile(orig) as z:
 prefix='claw_and_co_gates_A_D/'
 for f in list((P/'scripts').rglob('*.gd')):
  relative=f.relative_to(P).as_posix()
  if relative not in ['scripts/managers/CartManager.gd','scripts/core/SimulationRoot.gd'] and 'scripts/presentation/' not in relative and 'scripts/tests/' not in relative:
   check(z.read(prefix+relative)==f.read_bytes(),'unchanged frozen simulation '+relative)
passed=sum(ok for ok,_ in checks)
log=P/'logs/gate_e_refactor_static.log'
log.write_text('STATIC PREFLIGHT ONLY — NOT GODOT RUNTIME\n'+ '\n'.join(('PASS' if ok else 'FAIL')+' | '+label for ok,label in checks)+f'\nRESULT {passed}/{len(checks)} static checks\n')
print(f'STATIC CHECKS: {passed}/{len(checks)}')
print('GODOT_RUNTIME: UNAVAILABLE — NOT RUN')
sys.exit(0 if passed==len(checks) else 1)
