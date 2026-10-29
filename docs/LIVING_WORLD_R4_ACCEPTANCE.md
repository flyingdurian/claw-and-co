# CLAW & CO. — Living-World R4 acceptance contract

## Approved visual references

Both owner-approved Akihabara screenshots are style masters, particularly the latest full-aisle illustration with neon cabinets, multiple layers of animated patrons and the detailed 4+2+2+2+1 trolley. These are visual art-direction assets, **not** proof of game capture.

## Owner's non-negotiables

1. **True illustrated frame-by-frame or separated-part animation:** no portrait wiggling, sliding a flat person, or substituting a pantomime of motion for gait, hand interaction, eye direction, mouth phonemes and expressions.
2. **Walk-through world:** customers and spectators exist at a far/middle/near depth, move on authored paths, emerge from deep arcade corridors, maintain proportion and floor contact, interact and exit; a painted-on crowd does not count.
3. **Functional autonomous cabinets:** mechanism plays the authored machine attempt including grab, contact, tip, miss, prize output, blocked reset, load/unload. All inventory remains owned by the accepted simulation ledger.
4. **Demand-driven requests:** only stage-authored service states and actual reset faults raise interactive bubbles. Others may idle, browse, play, cheer and react without displaying an order card.
5. **Rush pacing:** stage wave manifest, not ambient pose timing, governs requests, queues and patience. Animated ambient traffic may be visual-only and deterministic.
6. **No playable walking avatar.** First-person aisle and workshop with persistent tactile service cart.

## Progress provided in R4

- `PerspectiveCrowdRoutes.gd` defines tick-addressable far-to-near trajectories and scale from 0.16 to 0.84, with a genuine rear crowd layer behind cabinets, and front-depth reparenting.
- `ArcadeAisle` and `CustomerView` present demand bubbles only for actionable customer service and the machine's reset-required state.
- `MachinePerformanceTimeline.gd` defines state- and attempt-result-driven motion curves for M01-M04, including win, miss, stuck, Staff Key, chute, restock and attract-loop cues. It is a presentation-only script; authoritative simulation unchanged.
- `ArticulatedCustomerRig.gd` establishes an image-layer articulation and expression texture contract. **No complete artist rig exports are included. The current customer fallback still uses R3's insufficient cutout frames, and visual acceptance therefore remains BLOCKED.**

## Art pipeline required before presentation acceptance

For each final customer, author cohesive transparent 2D parts: torso, head, both upper arms, both forearms, both thighs, both shins, hairstyles, hands, eyelid/eye sets, mouth expressions, carried prizes; provide 8-12 direction-consistent gait keys, talking/mouth and head turns, concentration, frustration, near-miss, cheer, collect, hold and leave. Use 2D sprite part pivots and authored expression atlases. Do not extract live people from screenshot pixels; do not bake patrons into a background. Painted backgrounds must contain scenery only.

`res://art/performers/<character_id>/rig.json` specifies pivot locations and layer z-order; `ArticulatedCustomerRig.art_complete()` must return true for each actor before disabling the legacy fallback. Art should be exported by a real animation artist or consistent character-generation pipeline rather than hacked motion-simulated stills.

## Required real-engine evidence for closure

- Godot 4.7.2 import with zero missing nodes/textures, zero runtime errors.
- Gameplay at 1280x720 showing wide shot at 0s/30s/60s/90s/120s and at least one far-to-near traversing patron.
- 30 or 60 fps footage of walking limbs, chatting face changes, playing, frustration, winning, prize pick-up and leaving with natural foot contact.
- Distinct cabinet internal play, help reset (90 ticks), missed M03 attempt (stock conserved), successful prize dispense, cassette restock (stock changes visually).
- A–D headless replay acceptance hash unchanged; Gate E interaction tests and new R4 crowd/depth suite pass.
- Actual Godot captures compared side-by-side to BOTH approved references by the owner. No offline comp is acceptable evidence.

## Non-claims

This R4 package adds executable systems and tests, but it **does not claim** near-identical visual parity or complete character animation while production-ready articulated art is missing. The user-provided R3 MP4 shows the deficiency: substantially static source cutouts with limited bob/warp, not full-body motion.
