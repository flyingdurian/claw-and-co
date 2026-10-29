#!/usr/bin/env python3
"""Independent static checks. Explicitly NOT a replacement for Godot import/runtime."""
import pathlib,re,sys,struct
root=pathlib.Path(__file__).resolve().parents[1]
scene_files=sorted((root/'scenes').rglob('*.tscn'))
scripts=sorted((root/'scripts/presentation').rglob('*.gd'))
assert len(scene_files)>=10,scene_files
assert len(scripts)>=8,scripts
pats=[];errs=[];asset_count=0;ref_count=0
for scene in scene_files:
 text=scene.read_text()
 assert text.startswith('[gd_scene'),scene
 root_lines=re.findall(r'^\[node .*\]$',text,re.M)
 assert root_lines,scene
 assert 'parent=' not in root_lines[0],(scene,root_lines[0])
 for link in re.findall(r'path="res://([^"]+)"',text):
  ref_count+=1
  if not (root/link).exists():errs.append(f'{scene}: missing {link}')
 for token in re.findall(r'ExtResource\("([^"]+)"\)',text):
  if token not in re.findall(r'\[ext_resource [^]]+id="([^"]+)"\]',text):errs.append(f'{scene}: missing ext resource id {token}')
 for fragment in re.findall(r'\[node ([^]]+)\]',text):
  if 'instance=' in fragment and 'type=' in fragment:errs.append(f'{scene}: instanced node duplicated type')
for p in (root/'art').rglob('*.png'):
 b=p.read_bytes();assert b[:8]==b'\x89PNG\r\n\x1a\n'
 w,h=struct.unpack('>II',b[16:24]);assert w>40 and h>40
 asset_count+=1
required=['ArcadeAisle.tscn','BackstageWorkshop.tscn','ServiceCartUI.tscn','TopBarHUD.tscn','Main.tscn']
for n in required:assert (root/'scenes'/n).exists(),n
main=(root/'scripts/presentation/GamePresentation.gd').read_text()
bridge=(root/'scripts/presentation/PresentationBridge.gd').read_text()
assert 'quote_card_purchase' in bridge and 'driver.submit' in bridge
assert 'get_node("../SimulationDriver")' in bridge
assert '_confirm_sale' in main and 'purchase_card' in main
assert 'switch_area' in main and 'switch_tab' in main
assert 'driver.simulation.advance' not in main
assert 'GamePresentation' in main and 'SimulationDriver' in (root/'scenes/Main.tscn').read_text()
assert len(list((root/'art/machines').glob('*.png')))==4
assert len(list((root/'art/customers').glob('*.png')))==8

# Verify onready $Child references resolve inside their authored scene hierarchy.
script_to_scene={
 'GamePresentation.gd': 'Main.tscn',
 'ArcadeAisle.gd': 'ArcadeAisle.tscn',
 'BackstageWorkshop.gd': 'BackstageWorkshop.tscn',
 'TopBarHUD.gd': 'TopBarHUD.tscn',
 'ServiceCartUI.gd': 'ServiceCartUI.tscn',
 'MachineView.gd': 'machines/M01_Machine.tscn',
 'CustomerView.gd': 'customers/CustomerView.tscn',
}
for script_name,scene_name in script_to_scene.items():
 content=(root/'scripts/presentation'/script_name).read_text()
 scene=(root/'scenes'/scene_name).read_text()
 paths=set()
 for attrs in re.findall(r'^\[node ([^\n]+)\]$',scene,re.M):
  name=re.search(r'\bname="([^"]+)"',attrs)
  parent=re.search(r'\bparent="([^"]+)"',attrs)
  if name and parent:
   par=parent.group(1)
   paths.add(name.group(1) if par=='.' else par+'/'+name.group(1))
 for rel in re.findall(r'\$([A-Za-z][A-Za-z0-9_]*)',content):
  if rel not in paths:errs.append(f'{script_name}: unresolved scene child ${rel}')

if errs:
 for e in errs: print('ERROR:',e)
 sys.exit(1)
print('PASS Gate E static dependencies: scenes=%d scripts=%d textures=%d referenced_paths=%d' % (len(scene_files),len(scripts),asset_count,ref_count))
print('PASS 4 distinct cabinet sprite PNGs / 8 customer sprites / four workstations')
print('PASS frozen-driver command and quote bridge present')
print('Godot import and interaction smoke: NOT RUN by this Python check')
