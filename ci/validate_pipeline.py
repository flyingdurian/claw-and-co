#!/usr/bin/env python3
"""Static CI preflight: fails closed and verifies source was not silently replaced."""
from pathlib import Path
import json,sys,hashlib,subprocess
ROOT=Path(__file__).resolve().parents[1]
checks=[]
def check(ok,what):
    checks.append(bool(ok))
    print(('PASS' if ok else 'FAIL'),what)
check((ROOT/'project.godot').exists(),'Godot project exists at repository root')
text=(ROOT/'project.godot').read_text()
check('1280' in text and '720' in text, '1280x720 viewport configured')
check('60' in text, '60Hz stage simulation configured')
for f in ['scenes/Main.tscn','scripts/tests/RunTests.gd','scripts/tests/RunGateETests.gd','scripts/tests/RunGateERefactorTests.gd','scripts/tests/RunLivingWorldTests.gd','scripts/tests/RunPerspectiveCrowdTests.gd','scripts/tests/RunMachinePerformanceTests.gd','docs/references/approved_gate_e_akihabara_composite.png','docs/references/approved_living_arcade_full_aisle.png']:
    check((ROOT/f).is_file(), f'Project dependency {f}')
for f in ['.github/workflows/godot-review.yml','ci/CaptureReview.gd','ci/fetch_godot.py','ci/run_suites.sh','ci/run_capture.sh']:
    check((ROOT/f).is_file(),f'CI dependency {f}')
manifest=json.loads((ROOT/'ci/frozen_baseline.json').read_text())
for rel,sha in manifest['untouched_source_sha256'].items():
    p=ROOT/rel
    check(p.exists() and hashlib.sha256(p.read_bytes()).hexdigest()==sha, f'Frozen source unchanged: {rel}')
try:
    import yaml
    print('YAML parser available, checking workflow syntax')
    with (ROOT/'.github/workflows/godot-review.yml').open() as fh: yaml.load(fh,Loader=yaml.BaseLoader)
except ImportError:
    print('PyYAML unavailable: GitHub validates workflow syntax at first push')
except Exception as exc:
    check(False,'Workflow YAML invalid: '+str(exc))
print('STATIC_CI_CHECKS=',len(checks),'PASSED=',sum(checks),'FAILED=',len(checks)-sum(checks))
sys.exit(0 if all(checks) else 1)
