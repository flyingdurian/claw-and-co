#!/usr/bin/env python3
"""Original deterministic bell score and service cues, without samples."""
from pathlib import Path
import wave
import numpy as np
RATE=22050
OUT=Path(__file__).resolve().parents[1]/'art/neon_shift/audio'
OUT.mkdir(parents=True,exist_ok=True)
def write(name,a):
 with wave.open(str(OUT/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes((np.clip(a,-1,1)*26000).astype('<i2').tobytes())
def tone(n,d,amp=.3):
 t=np.arange(int(RATE*d))/RATE;f=440*2**((n-69)/12)
 return amp*(1-np.exp(-t*75))*np.exp(-t*5/max(d,.1))*(np.sin(2*np.pi*f*t)+.22*np.sin(4*np.pi*f*t)+.08*np.sin(6*np.pi*f*t))
def cue(name,notes,spacing=.095,d=.28):
 a=np.zeros(int(RATE*(len(notes)*spacing+d)))
 for i,n in enumerate(notes):
  b=tone(n,d,.32);s=int(i*spacing*RATE);a[s:s+len(b)]+=b
 write(name,a)
cue('tap',[79],.07,.12);cue('success',[76,79,83],.075,.35);cue('error',[55,52],.08,.14);cue('complete',[72,76,79,84,83,79,84],.12,.55)
beat=.6;bars=8;duration=beat*4*bars
track=np.zeros(int(RATE*duration));rng=np.random.default_rng(11)
chords=[[48,55,59,64],[45,52,55,60],[41,48,52,57],[43,50,53,59]]
melodies=[[76,79,83,79,76,74,71,74],[72,76,79,76,72,71,69,72],[69,72,76,72,69,67,64,67],[71,74,79,77,74,71,67,74]]
def add(b,when):
 start=int(when*RATE);end=min(len(track),start+len(b));track[start:end]+=b[:end-start]
for bar in range(bars):
 root=chords[bar%4];t0=bar*4*beat
 for n in root:
  t=np.arange(int(RATE*beat*3.85))/RATE;f=440*2**((n-69)/12)
  env=np.minimum(1,t/.09)*np.minimum(1,(beat*3.85-t)/.25)*.025
  add(env*(np.sin(2*np.pi*f*t)+.2*np.sin(4*np.pi*f*t)),t0)
 for k,n in enumerate(melodies[bar%4]): add(tone(n,.28,.09),t0+k*beat/2)
 for k in range(4):
  t=np.arange(int(.18*RATE))/RATE;add(.08*np.exp(-t*25)*np.sin(2*np.pi*(50*t+3*(1-np.exp(-t*30)))),t0+k*beat)
  ht=np.arange(int(.035*RATE))/RATE;add(rng.normal(0,.013,len(ht))*np.exp(-ht*110),t0+k*beat+beat*.5)
track[:int(.05*RATE)]*=np.linspace(0,1,int(.05*RATE));track[-int(.2*RATE):]*=np.linspace(1,0,int(.2*RATE))
write('arcade_evening',track)
print('Generated five original audio tracks/cues')
