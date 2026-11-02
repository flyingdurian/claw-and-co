# CLAW & CO. — M01 V1 Common Prefix Pilot

Status: in development; isolated branch `r5/m01-v1-common-prefix-pilot`. Prior approved PR #2/PR #3 code remains source-of-truth in main.

V1 only: deterministic selector from stage ID, session ID, attempt index and visual seed, paired W1–M1, W2–M2, W3–M3. Exact same rendered pose, plush state and grip through visual tick 179. Resolution begins at tick 180. Authoritative gameplay Stage 1 still has a 240-tick attempt, 60-tick settling and 120-tick collection delay.

The visually carried prize remains the same exact reserved instance. It may temporarily follow the claw on an authored miss, after which the original cassette sprite becomes visible again. No virtual carry becomes a ledger transfer. The machine manager alone decides win, miss and inventory ownership.

The source selector is intentionally read-only. No stochastic per-frame choices. `RunM01VariationPilotTests.gd` tests all 180 matching prefix frames for each pair and uses separate authored miss fixtures. Capture evidence includes 18 1280x720 rendered in-engine states and composites at ticks 163, 205, 229.

Deferred: W4/W5, M4/M5, E1–E3, C1–C3, chute jams, player-controlled early drops, procedural collisions, physics-driven outcomes. No new early reveal UI or sound is permitted.
