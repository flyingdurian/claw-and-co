#!/usr/bin/env python3
"""Truthful image comparison; source is OWNER reference, target must be GODOT output.
No source art mock is ever passed off as an in-engine capture.
"""
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import numpy as np,cv2,sys
root=Path(__file__).resolve().parent.parent
baseline=Image.open('/mnt/data/image(20261028-165956).png').convert('RGB').crop((0,0,1160,607)).resize((1280,720),Image.Resampling.LANCZOS) if Path('/mnt/data/image(20261028-165956).png').is_file() else Image.open(root/'art/parity/arcade_backdrop.png').convert('RGB')
capture=root/'previews/gate_e_runtime_arcade_1280x720.png'
if not capture.exists():
 msg='RUNTIME PARITY NOT YET EVALUATED: no real Godot 1280x720 screenshot. Offline art comparison available separately.\n'
 (root/'logs/gate_e_visual_comparison.txt').write_text(msg)
 print(msg.rstrip()); sys.exit(2)
render=Image.open(capture).convert('RGB')
if render.size!=(1280,720): raise SystemExit('Godot capture is not exactly 1280x720')
a=np.asarray(baseline,dtype=np.int16);b=np.asarray(render,dtype=np.int16)
mask=np.zeros((720,1280),bool);mask[:512,:]=True
region_mae=float(np.mean(abs(a[mask]-b[mask])))
full_mae=float(np.mean(abs(a-b)))
# normalized structural similarity index in OpenCV without requiring scikit-image
ag=cv2.cvtColor(np.uint8(a),cv2.COLOR_RGB2GRAY).astype('float64');bg=cv2.cvtColor(np.uint8(b),cv2.COLOR_RGB2GRAY).astype('float64')
mu_a=cv2.GaussianBlur(ag,(11,11),1.5);mu_b=cv2.GaussianBlur(bg,(11,11),1.5)
va=cv2.GaussianBlur(ag*ag,(11,11),1.5)-mu_a*mu_a
vb=cv2.GaussianBlur(bg*bg,(11,11),1.5)-mu_b*mu_b
ab=cv2.GaussianBlur(ag*bg,(11,11),1.5)-mu_a*mu_b
ssim=(2*mu_a*mu_b+6.5025)*(2*ab+58.5225)/((mu_a**2+mu_b**2+6.5025)*(va+vb+58.5225))
region_ssim=float(np.nanmean(ssim[mask]))
side=Image.new('RGB',(2560,765),'#0e1732');side.paste(baseline,(0,45));side.paste(render,(1280,45));d=ImageDraw.Draw(side)
d.text((22,16),'APPROVED SOURCE COMPOSITE — NOT GAMEPLAY',fill='white')
d.text((1302,16),'ACTUAL GODOT SCREENSHOT — 1280x720',fill='white')
side.save(root/'previews/gate_e_runtime_side_by_side.png')
log=f'GODOT RUNTIME VISUAL COMPARISON\nSource: owner composite left crop, scaled to 1280x720\nRendered: {capture.name}\nRegion excluding cart (0<=y<512) MAE RGB: {region_mae:.2f} of 255\nRegion structural similarity: {region_ssim:.4f}\nFull image MAE RGB: {full_mae:.2f} of 255\nNOTE: New tactile cart is intentionally different; no blanket parity claim based on pixel metrics.\n'
(root/'logs/gate_e_visual_comparison.txt').write_text(log)
print(log)
