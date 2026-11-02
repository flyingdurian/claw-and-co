#!/usr/bin/env python3
"""ART-01 preflight only: validates file properties, never declares identity match."""
from pathlib import Path
from PIL import Image
import argparse,json,hashlib,sys
def main():
 p=argparse.ArgumentParser()
 p.add_argument('candidate',type=Path)
 p.add_argument('--out',type=Path,default=Path('ci/output/r4a-art01/identity_validation.json'))
 args=p.parse_args()
 errors=[]
 if not args.candidate.is_file():
  errors.append('ART-01: no actual production master at '+str(args.candidate))
  data={'gate':'ART-01','status':'BLOCKED','errors':errors}
 else:
  im=Image.open(args.candidate)
  if im.mode!='RGBA':errors.append('Lossless RGBA PNG with transparency is required')
  if im.format!='PNG':errors.append('Candidate is not PNG')
  w,h=im.size
  if h<1900:errors.append('Master must be approximately 2048px high (minimum 1900px)')
  if w<650:errors.append('Master width too small for full-body registration')
  alpha=im.getchannel('A') if im.mode=='RGBA' else None
  bbox=alpha.getbbox() if alpha is not None else None
  if bbox is None:errors.append('No opaque subject pixels')
  else:
   if bbox[0]<15 or bbox[1]<15 or bbox[2]>w-15 or bbox[3]>h-15:
    errors.append('Image touches canvas edge: transparent padding required')
   if alpha.getextrema()[0]>0:errors.append('True transparent background required')
  data={'gate':'ART-01','status':'TECHNICAL_READY_ART_PENDING' if not errors else 'BLOCKED',
   'candidate':str(args.candidate),'size':[w,h],'bbox':bbox,
   'sha256':hashlib.sha256(args.candidate.read_bytes()).hexdigest(),'errors':errors,
   'visual_owner_approval':'PENDING','modular_assembly':'NOT_STARTED'}
 args.out.parent.mkdir(parents=True,exist_ok=True)
 args.out.write_text(json.dumps(data,indent=2)+'\n')
 print(json.dumps(data))
 return 1 if errors else 0
if __name__=='__main__':sys.exit(main())
