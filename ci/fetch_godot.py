#!/usr/bin/env python3
"""Fetch the official Godot Linux editor by tag AND SHA-256 GitHub release metadata.
Does not download/execute an unsigned arbitrary 'latest' build.
"""
import hashlib, json, os, pathlib, urllib.request, zipfile
TAG = '4.7.2-stable'
FILENAME = 'Godot_v4.7.2-stable_linux.x86_64.zip'
API = f'https://api.github.com/repos/godotengine/godot-builds/releases/tags/{TAG}'
ROOT = pathlib.Path(__file__).resolve().parent
BIN = ROOT / 'bin'
BIN.mkdir(parents=True, exist_ok=True)
headers = {'User-Agent': 'ClawCo-Godot-CI/1.0', 'Accept': 'application/vnd.github+json'}
if os.environ.get('GITHUB_TOKEN'):
    headers['Authorization'] = 'Bearer '+os.environ['GITHUB_TOKEN']
def read_url(url):
    with urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=90) as r:
        return r.read()
release = json.loads(read_url(API))
asset = next((a for a in release['assets'] if a['name'] == FILENAME), None)
if asset is None:
    raise SystemExit(f'Missing official Godot 4.7.2 Linux release asset: {FILENAME}')
digest = asset.get('digest','')
if not digest.startswith('sha256:') or len(digest) != 71:
    raise SystemExit('Missing GitHub-provided SHA256 digest; refusing unverified download')
print('Downloading verified binary:', FILENAME, flush=True)
archive = BIN / FILENAME
archive.write_bytes(read_url(asset['browser_download_url']))
actual = hashlib.sha256(archive.read_bytes()).hexdigest()
if actual != digest.split(':',1)[1]:
    archive.unlink(missing_ok=True)
    raise SystemExit('SHA256 mismatch; refusing executable')
with zipfile.ZipFile(archive) as z:
    names = [n for n in z.namelist() if not n.endswith('/')]
    if len(names) != 1 or pathlib.PurePosixPath(names[0]).name != FILENAME.removesuffix('.zip'):
        raise SystemExit(f'Unexpected archive layout: {names!r}')
    content=z.read(names[0])
exe = BIN/'godot'
exe.write_bytes(content)
exe.chmod(0o755)
archive.unlink()
print('Verified official Godot 4.7.2 binary sha256:', actual)
