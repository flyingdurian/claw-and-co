#!/usr/bin/env python3
"""Report evidence provenance and distinguish visual acceptance from test success."""
from pathlib import Path
import os,datetime,json,hashlib
p=Path(__file__).resolve().parent/'output'
p.mkdir(parents=True,exist_ok=True)
ss=sorted(x.name for x in (p/'screenshots').glob('*.png')) if (p/'screenshots').exists() else []
movie=p/'movie/arcade_10s.mp4'
report={
 'stage':'CI pipeline provisioning (R5 before visual rebuild)',
 'engine':'Godot 4.7.2 stable (verified by job if installation succeeds)',
 'commit_sha':os.environ.get('GITHUB_SHA','local-unpublished'),
 'screenshots':ss,
 'movie_recording':movie.exists() and movie.stat().st_size>0,
 'benchmark_comparisons':sorted(x.name for x in (p/'comparisons').glob('*.png')) if (p/'comparisons').exists() else [],
 'runner_renderer':(p/'renderer.txt').read_text().strip() if (p/'renderer.txt').exists() else 'not captured',
 'godot_headless_tests':'Consult logs/status.txt',
 'articulated_character_art':'Known R4 acceptance blocker until real rig assets exist',
 'visual_parity_approved':False,
 'owner_acceptance':'pending',
 'generated_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()
}
(p/'review_manifest.json').write_text(json.dumps(report,indent=2)+'\n')
lines=['# CLAW & CO. — CI visual review evidence','', 'Status: **Not owner-accepted**. CI captures are evidence, not automatic fidelity approval.','',f"Commit: `{report['commit_sha']}`",f"Renderer: `{report['runner_renderer']}`",'', '## Generated evidence']
lines.extend('- '+x for x in ss)
lines.extend('- Benchmark side-by-side: '+x for x in report['benchmark_comparisons'])
lines.append('- Ten-second Godot MP4: '+('present' if report['movie_recording'] else 'NOT CREATED'))
lines +=['', '## Review gates','', '- Godot import/actual script tests: see `logs/status.txt`','- Strict character modular-art gate: see `logs/RunR4ArtAcceptance.log`; known incomplete in R4.1','- Forward+ Windows GPU fidelity: **not tested** by Linux GL software capture','- Approved benchmark parity: **not determined** automatically','', 'Never treat an offline concept image as an engine capture.']
(p/'REVIEW.md').write_text('\n'.join(lines)+'\n')
print('\n'.join(lines))
