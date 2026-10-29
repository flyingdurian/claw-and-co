#!/usr/bin/env python3
import pathlib,subprocess,json,sys,struct
out=pathlib.Path(__file__).resolve().parent/'output'
ss=sorted((out/'screenshots').glob('*.png'))
if len(ss)!=5:
    sys.exit(f'FAIL: expected 5 Godot screenshots, found {len(ss)}')
for p in ss:
    b=p.read_bytes()
    if b[:8]!=b'\x89PNG\r\n\x1a\n' or struct.unpack('>II',b[16:24]) != (1280,720):
        sys.exit(f'FAIL: bad native 1280x720 image {p}')
vid=out/'movie/arcade_10s.mp4'
if not vid.is_file() or vid.stat().st_size < 10000:
    sys.exit('FAIL: video file missing or very small')
p=subprocess.run(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=width,height,nb_frames','-of','json',str(vid)],capture_output=True,text=True,check=True)
streams=json.loads(p.stdout)['streams']
if not streams or (int(streams[0]['width']),int(streams[0]['height']))!=(1280,720):
    sys.exit('FAIL: wrong video resolution')
print('CAPTURE_VERIFIED native_1280x720_screenshots=',len(ss),'video_bytes=',vid.stat().st_size)
