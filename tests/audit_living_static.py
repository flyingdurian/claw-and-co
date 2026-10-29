"""Offline reference/static integrity audit; never substitutes for a Godot import/run."""
from pathlib import Path
from PIL import Image
import hashlib,json,re,sys
P=Path(__file__).resolve().parents[1]
original=Path('/mnt/data/claw_gate_e_refactor/claw_and_co_gates_A_D')
checks=0;failed=[]
def test(ok,label):
 global checks
 checks+=1
 if not ok: failed.append(label)

stage=json.loads((P/'data/stage_01.json').read_text())
test(stage['tick_hz']==60,'60Hz stage fixed clock')
test(stage['duration_ticks']==7200,'120s fixed stage length')
test(sum(len(w['visits']) for w in stage['waves'])==8,'eight authored visits')
reflist=[]
for scene in P.glob('scenes/**/*.tscn'):
 content=scene.read_text()
 for ref in re.findall(r'\bpath="(res://[^"]+)"',content):
  test((P/ref[6:]).is_file(),f'scene reference {scene.relative_to(P)}:{ref}')
  reflist.append(ref)
 test('ColorRect' not in content and 'Polygon2D' not in content,'no primitive scene placeholder '+str(scene.relative_to(P)))
for source in P.glob('scripts/**/*.gd'):
 content=source.read_text()
 for ref in re.findall(r'(?:res://[^"\s\']+\.(?:gd|png|tscn))',content):
  if '%' in ref or '+' in ref:continue
  test((P/ref[6:]).is_file(),f'gd resource reference {ref}')
# Animated sprites for every character/pose. All must have transparency and valid dimensions.
for i in range(1,11):
 for pose in ['walk','play','chat','cheer','miss','watch','hold']:
  for f in range(4):
   path=P/f'art/living/actor_{i:02d}_{pose}_{f}.png'
   test(path.is_file(),f'pose exists {i}:{pose}:{f}')
   if path.is_file():
    img=Image.open(path)
    test(img.mode=='RGBA' and img.width>=100 and img.height>=200,f'pose valid {i}:{pose}:{f}')
for mid in ['M01','M02','M03','M04']:
 scene=(P/f'scenes/machines/{mid}_Machine.tscn').read_text()
 for layer in ['BaseBody','PrizeInterior','Mechanism','StockHero','ChutePrize','SpecularGlassOverlay','NeonMarquee','GlowLight']:
  test(f'[node name="{layer}"' in scene,f'{mid}:{layer}')
 for suffix in ['base_clean','glass','interior']:
  item=P/f'art/living/{suffix}_{mid}.png'
  test(item.is_file(),f'{mid}:{suffix}')
for rel in ['InventoryLedger.gd','SchemaLoader.gd','SimulationClock.gd','SimulationDriver.gd','SimulationRoot.gd']:
 test((original/'scripts/core'/rel).read_bytes()==(P/'scripts/core'/rel).read_bytes(),f'frozen simulation core {rel}')
for rel in ['MachineManager.gd','CustomerManager.gd','WorkshopManager.gd','CartManager.gd']:
 test((original/'scripts/managers'/rel).read_bytes()==(P/'scripts/managers'/rel).read_bytes(),f'frozen manager {rel}')
for rel in ['data/stage_01.json','project.godot']:
 test((original/rel).read_bytes()==(P/rel).read_bytes(),f'frozen manifest/config {rel}')
text='\n'.join((P/'scripts/presentation'/n).read_text() for n in ['LiveCrowdDirector.gd','LiveActor.gd','MachineView.gd'])
for forbidden in ['randf(', 'randi(', 'randomize(', 'OS.get_ticks_','Time.get_ticks_']:
 test(forbidden not in text, f'no unscheduled chance/time {forbidden}')
for condition in ['MISS_RELEASED','RESET_REQUIRED','OUTPUT_HELD','TRY_AGAIN','HOLD_PRIZE','CHEER','FRUSTRATED','PLAY']:
 test(condition in text,f'reaction/animation {condition}')
for f in ['scripts/tests/RunLivingWorldTests.gd','scripts/tests/CaptureLivingSequences.gd','tests/run_living_world.ps1','tests/run_living_world.sh']:
 test((P/f).is_file(),f'engine validation deliverable {f}')
# GDScript text balance: catches common accidental truncations, not a compiler replacement.
for src in P.glob('scripts/presentation/*.gd'):
 t=src.read_text()
 for left,right in [('(',')'),('[',']'),('{','}')]:
  # strip # comments and quoted literals (simple, adequate for our syntax)
  clean='\n'.join(line.split('#')[0] for line in t.splitlines())
  clean=re.sub(r'"(?:\\.|[^"\\])*"','""',clean)
  test(clean.count(left)==clean.count(right),f'punctuation balance {src.name} {left}')
log=P/'logs/living_static_audit.log'
log.write_text(f'OFFLINE_STATIC_CHECKS={checks}\nOFFLINE_STATIC_FAILURES={len(failed)}\n'+ '\n'.join('FAIL: '+v for v in failed) +'\nGODOT_RUNTIME_TESTS=NOT_RUN_IN_THIS_ENVIRONMENT\n')
print(log.read_text())
sys.exit(1 if failed else 0)
