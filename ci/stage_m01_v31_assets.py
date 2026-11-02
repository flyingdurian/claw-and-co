#!/usr/bin/env python3
import base64, hashlib, json, re, sys, zipfile
from pathlib import Path
from PIL import Image
from io import BytesIO
root=Path(__file__).resolve().parents[1]
out=root/'art/m01_v31'; out.mkdir(parents=True,exist_ok=True)
data=root/'data/r5';data.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(sys.argv[1]) as z:
 checks=json.loads(z.read('SHA256_MANIFEST.json'))
 for n,c in checks.items():
  b=z.read(n)
  assert len(b)==c['bytes'] and hashlib.sha256(b).hexdigest()==c['sha256'],n
 cfg=json.loads(z.read('ClawCo_M01_Gantry_Studio_V31_Calibration.json'))
 assert cfg['version']==3.1 and cfg['bridge']['visual_scale_percent']==105
 (data/'M01V31Calibration.json').write_text(json.dumps(cfg,indent=2))
 (out/'M01Cabinet.png').write_bytes(z.read('M01 Raspberry Claw Cabinet Body.png'))
 html=z.read('M01_Precision_Gantry_Studio_V31.html').decode()
 matches=re.findall(r'"([a-z_0-9]+)":"data:image/(?:png|webp|jpeg);base64,([A-Za-z0-9+/=]+)"',html)
 assert len(matches)==25,len(matches)
 for name,b64 in matches:
  Image.open(BytesIO(base64.b64decode(b64))).convert('RGBA').save(out/(name+'.png'),optimize=True)
 pillar=Image.open(out/'front_left_pillar_only_mask.png').convert('RGBA')
 pillar.save(out/'left_pillar_occlusion.png')
 roof=Image.open(out/'roof_fascia_mask.png').convert('RGBA')
 chain=Image.new('RGBA',roof.size)
 crop=(346,304,476,387)
 chain.paste(roof.crop(crop),crop[:2])
 chain.save(out/'chain_feed_occlusion.png')
 print('V31_ASSETS_OK',len(matches))
