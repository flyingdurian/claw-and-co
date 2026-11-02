# ART-02 — High-fidelity Actor 01 modular art reconstruction

Approved identity: `art/performers/actor_01/identity_master_candidate.png`, SHA-256 `dfc1312937313976179bf5cb830f088e79134eb9018fce09a468ed1b943e81e3`. This owner-approved image is **not** a modular production rig and must remain unmodified.

**Art status: not yet reconstructed.** This folder contains a strict production/export contract and validator, not falsely approved layers.

## Required export
The registration schema lists 35 independent full-color, transparent PNG layers or expression variants covering head and face, ponytail and front/rear hair, bow, hood and hoodie, skirt, backpack/straps/charm, upper arms, forearms, hands, thighs, shins, socks and detailed sneakers. Each must be finished at the same painterly resolution, rendering angle, light direction and color palette as the approved original.

For every asset, the artist must **paint previously occluded surfaces** (upper-arm sleeve caps beneath the torso, forearm cloth beneath sleeves, neck/back scalp under hair, thighs under skirt, knees under socks, shoe tongues/ankle collars, and ponytail root). A direct crop with transparent missing areas fails ART-02 even if the neutral sprite looks correct. Correct skin/clothing joint overlap, fabric deformation coverage and edge bleed are required.

## Registration
Manifest: `docs/art/actor01_art02_registration.json`.
Source coordinate system: 1024×1536 native pixel positions with y positive down. Every layer needs neutral bbox, exact neutral top-left, pivot_local, z-order, parent joint and a hidden-anatomy note. Provisional joint source positions in the manifest must be calibrated by real painterly artwork and full-size Godot captures; they are not owner-approved engineering coordinates.

## Evidence before MOT-01
- Genuine Godot 4.7.2 1280×720 neutral assembled frame, source/assembly side by side at 1:1.
- Native-resolution detail crops of face, hair/bow, cuffs/elbows, knees/socks, shoes and bag.
- Godot articulation extreme screenshots with clean overlaps and no gaps.
- Full hash/alpha/size/placement validation, source provenance and owner discrepancy register.
- Only after owner's explicit ART-02 visual approval may MOT-01 begin.

Run `python3 tools/validate_actor01_art02.py --repo-root . --out ci/output/r4a-art02`. Until real layer files exist, this intentionally reports missing assets and returns nonzero. The original 128px SVG suite remains a non-production rig diagnostic and is never accepted as ART-02 art.
