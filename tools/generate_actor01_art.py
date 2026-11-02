#!/usr/bin/env python3
"""Reproducible original Actor 01 modular 2D illustration pilot.
Each part is a standalone editable vector artwork with transparent surroundings.
Not a screenshot cutout, not a stand-in for owner visual acceptance.
"""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]/"art/performers/actor_01"
R.mkdir(parents=True,exist_ok=True)
defs="""<defs>
<linearGradient id="skin" x2=".7" y2="1"><stop stop-color="#fff1df"/><stop offset=".55" stop-color="#ffd6c2"/><stop offset="1" stop-color="#efac9b"/></linearGradient>
<linearGradient id="pink" x2=".8" y2="1"><stop stop-color="#ffd1e4"/><stop offset=".45" stop-color="#fc83b8"/><stop offset="1" stop-color="#d44789"/></linearGradient>
<linearGradient id="ruby" x2=".9" y2="1"><stop stop-color="#fb93ba"/><stop offset="1" stop-color="#a83170"/></linearGradient>
<linearGradient id="hair" x2="1" y2="1"><stop stop-color="#a16b52"/><stop offset=".46" stop-color="#653b35"/><stop offset="1" stop-color="#30222e"/></linearGradient>
<linearGradient id="navy" x2=".8" y2="1"><stop stop-color="#62627a"/><stop offset=".8" stop-color="#332d46"/><stop offset="1" stop-color="#211b31"/></linearGradient>
<linearGradient id="white" x2=".6" y2="1"><stop stop-color="#ffffff"/><stop offset="1" stop-color="#afd8ed"/></linearGradient>
<radialGradient id="blush"><stop stop-color="#ff8f99" stop-opacity=".62"/><stop offset="1" stop-color="#ff8f99" stop-opacity="0"/></radialGradient>
</defs>"""
o='stroke="#5b3449" stroke-width="2.8" stroke-linejoin="round" stroke-linecap="round"'
def P(d,fill,extra=''):
 return f'<path d="{d}" fill="{fill}" {o} {extra}/>'
def E(x,y,rx,ry,fill,extra=''):
 return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" {extra}/>'
A={}
A['torso']=P("M-31 -3 Q-25 -11 -15 -9 L16 -9 Q27 -9 31 -1 L35 41 L24 54 L-24 54 L-35 41 Z","url(#pink)")
A['torso']+=P("M-18 39 L17 39 L32 64 L-32 64 Z","url(#navy)")
A['torso']+=P("M-27 48 L26 48 M-27 55 L26 55","none",'stroke="#a5a0bd" stroke-width="1.6"')
A['torso']+=P("M-20 -4 L0 16 L20 -4","none",'stroke="#ffe8f4" stroke-width="3.5"')+P("M-13 18 Q0 8 13 18 L9 35 L-9 35 Z","#ffe9f4")
A['torso']+=E(0,25,6.5,6,"#fff")+E(-2,24,1.5,2,"#513c52")+E(2,24,1.5,2,"#513c52")+P("M-19 0 L-16 25 M18 0 L16 25","none",'stroke="#fff1f7" stroke-width="2"')
A['torso']+=E(-24,18,5,14,"#fff",'opacity=".16" transform="rotate(7 -24 18)"')
A['head']=E(0,0,43,43,"url(#skin)",o)+E(-26,15,15,11,"url(#blush)")+E(26,15,15,11,"url(#blush)")
A['head']+=P("M-31 20 Q-16 37 1 40 Q20 38 33 19","none",'stroke="#fff4ec" stroke-width="2" opacity=".5"')
A['hair_back']=P("M-43 -18 Q-51 -52 -18 -55 Q15 -62 35 -44 Q48 -34 45 3 L43 45 Q32 56 29 42 L-32 42 Q-45 58 -48 37 Z","url(#hair)")
A['hair_back']+=P("M-37 -24 Q-57 -5 -54 17 Q-64 28 -52 43 L-34 33","url(#hair)")+P("M32 -26 Q55 -7 53 17 Q59 32 47 43 L35 32","url(#hair)")
A['hair_back']+=P("M-35 -30 Q-20 -48 -5 -47 M8 -50 Q28 -45 37 -31","none",'stroke="#dba275" stroke-width="2.3" opacity=".85"')
A['hair_front']=P("M-44 -22 Q-49 -49 -22 -54 Q13 -60 35 -41 Q43 -29 43 -20 Q24 -32 16 -24 Q5 -40 -8 -23 Q-25 -30 -40 -10 Z","url(#hair)")
A['hair_front']+=P("M-32 -34 Q-20 -47 -7 -43 M9 -47 Q23 -43 31 -31","none",'stroke="#e4a475" stroke-width="2.7" opacity=".8"')
A['bow']=P("M-38 -45 Q-59 -64 -61 -48 Q-62 -39 -42 -37 Q-27 -35 -29 -46 Q-18 -60 -15 -43 Q-14 -33 -30 -38","url(#pink)")
A['bow']+=E(-32,-43,7,7,"#dc397e",o)+P("M-34 -40 L-39 -30 L-28 -34","url(#ruby)")
for side in ('l','r'):
 sign=-1 if side=='l' else 1
 A['upper_arm_'+side]=P("M-10 -2 Q-18 2 -15 17 L-12 31 Q0 38 12 30 L15 15 Q15 -7 -10 -2 Z","url(#pink)")+E(-5,7,4,10,"#fff",'opacity=".19"')
 A['upper_arm_'+side]+=P("M-12 27 Q0 33 11 27","none",'stroke="#ffe0ed" stroke-width="3"')
 A['forearm_'+side]=P("M-10 -4 Q0 -8 11 -3 L12 24 Q0 34 -11 26 Z","url(#pink)")
 A['forearm_'+side]+=P("M-10 22 Q0 26 11 22","none",'stroke="#ffe0ed" stroke-width="3"')
 A['hand_'+side]=P("M-9 -4 Q-15 1 -12 12 Q-10 24 2 21 Q14 15 10 4 Q5 -5 0 1 Q-4 -5 -9 -4 Z","url(#skin)")
 A['hand_'+side]+=P("M-6 10 Q0 7 6 12","none",'stroke="#e4a19a" stroke-width="1.3"')
 A['thigh_'+side]=P("M-10 -4 L10 -4 Q16 16 12 35 Q0 41 -11 35 Q-15 15 -10 -4 Z","url(#skin)")+E(-5,9,4,12,"#fff",'opacity=".19"')
 A['shin_'+side]=P("M-10 -4 L10 -4 L12 33 Q0 40 -12 33 Z","url(#white)")
 A['shin_'+side]+=P("M-10 3 L10 3 M-10 9 L11 9","none",'stroke="#ed8daf" stroke-width="3"')
 A['foot_'+side]=P("M-13 -7 Q0 -16 12 -7 L12 2 Q25 4 23 13 Q4 18 -18 15 Q-23 8 -13 -7 Z","url(#pink)")
 A['foot_'+side]+=P("M-18 12 Q0 17 23 12","none",'stroke="#fff" stroke-width="4"')+P("M-6 -1 L7 3 M-6 5 L8 9","none",'stroke="#ffe8f0" stroke-width="2"')
F={}
F['neutral']=E(-16,-1,7,9,"#34283d")+E(16,-1,7,9,"#34283d")+E(-18,-5,2.3,3,"#fff")+E(14,-5,2.3,3,"#fff")+P("M-5 19 Q0 24 5 19","none",'stroke="#a65e68" stroke-width="2.3"')
F['focus']=E(-16,0,7,9,"#34283d")+E(16,0,7,9,"#34283d")+E(-18,-4,2,3,"#fff")+E(14,-4,2,3,"#fff")+P("M-24 -13 L-9 -9 M9 -9 L24 -13 M-4 21 L4 21","none",'stroke="#855066" stroke-width="2.4"')
F['joy']=P("M-24 -1 Q-16 -14 -8 -1 M8 -1 Q16 -14 24 -1","none",'stroke="#493144" stroke-width="4"')+P("M-10 17 Q0 34 10 17 Z","#b34b68")
F['anticipation']=E(-16,-1,8,10,"#3e2b3e")+E(16,-1,8,10,"#3e2b3e")+E(-18,-6,3,3.5,"#fff")+E(13,-6,3,3.5,"#fff")+E(0,20,5,6,"#ae5066")
F['angry']=E(-16,0,7,8,"#3e2b3e")+E(16,0,7,8,"#3e2b3e")+P("M-24 -11 L-8 -4 M24 -11 L8 -4 M-8 24 Q0 15 8 24","none",'stroke="#8c4e63" stroke-width="3"')
F['sad']=P("M-24 0 Q-17 -9 -9 0 M9 0 Q17 -9 24 0 M-6 25 Q0 15 6 25","none",'stroke="#684758" stroke-width="3"')+P("M22 10 Q28 19 24 25 Q17 20 22 10 Z","#94d6ec")
F['speaking']=E(-16,-1,7,9,"#34283d")+E(16,-1,7,9,"#34283d")+E(-18,-4,2,3,"#fff")+E(14,-4,2,3,"#fff")+E(0,21,6,8,"#b8586d")
F['determined']=E(-16,-1,7,9,"#34283d")+E(16,-1,7,9,"#34283d")+P("M-24 -13 L-9 -6 M9 -6 L24 -13 M-6 21 Q0 23 6 21","none",'stroke="#805064" stroke-width="2.7"')
for emotion,visual in F.items():A['face_'+emotion]=visual
for part,visual in A.items():
 svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="-64 -64 128 128">{defs}{visual}</svg>\n'
 (R/(part+'.svg')).write_text(svg,encoding='utf-8')
manifest={
 "schema":"clawco.performer-rig/v2","character":"actor_01",
 "directory":"res://art/performers/actor_01","pixel_canvas":[128,128],
 "art_provenance":"Original separately illustrated vector parts — R4-A first visual pilot, not yet owner accepted",
 "joints":{"head":[0,-165],"shoulder_l":[-31,-122],"shoulder_r":[31,-122],
 "elbow_l":[0,31],"elbow_r":[0,31],"wrist_l":[0,27],"wrist_r":[0,27],
 "hip_l":[-14,-68],"hip_r":[14,-68],"knee_l":[0,35],"knee_r":[0,35],
 "ankle_l":[0,34],"ankle_r":[0,34]},
 "motions":{"walk_keys":12,"walk_period_ticks":48,"foot_plant_ratio":0.6,
 "actions":["REST","WALK","ARRIVE","ANTICIPATE","PLAY","CHEER","FRUSTRATED","LEAVE"]},
 "parts":[x for x in A if not x.startswith('face_')],
 "expressions":list(F),
 "visual_acceptance":"pending"
}
(R/'rig.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('ACTOR01_ORIGINAL_MODULAR_ASSETS=',len(A),'manifest='+str(R/'rig.json'))
