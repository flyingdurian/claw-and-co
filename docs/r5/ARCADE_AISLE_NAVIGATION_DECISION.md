# CLAW & CO. — Arcade Aisle Navigation Decision

**Decision:** APPROVED — 2026-10-29 (Vancouver).
**Selected by owner:** **Option A — dedicated third navigation stop for the mini-pantry.**

## Locked directional topology

Main Backstage Workshop is a separate full-service area accessed from the arcade. The continuous arcade traversal order is:

```text
[Front Arcade Aisle] ⇄ [Central Arcade Aisle] ⇄ [Mini-Pantry] ⇄ [Rear Arcade Aisle]
         ⇅
[Main Backstage Workshop]
```

This is a logical traversal diagram, not a final building floor plan. The Backstage entrance and optional future shortcuts require their own acceptance. No teleporting items or offscreen service delivery.

## What is actually approved

1. First-person management-only perspective: no controllable third-person avatar.
2. **Mini-Pantry is a dedicated third stop** on the arcade's normal forward/back navigation path, between the Central and Rear arcade aisles. It is **not** merely a side room or shared shortcut.
3. Its purpose is quicker access to a **finite, upgradeable subset of supplies**; it is **not** a second complete Workshop.
4. Playable machines along arcade aisles must be individually interactive; distant cabinet readability is addressed via camera positions/stops, not by turning visible machines into permanently painted props.
5. Customers remain an independently animated living population, potentially traveling between aisles. No baked patrons in environment plates.
6. Gameplay, inventory, machine activity, production and customer patience continue when an area is offscreen; navigation changes presentation, not authoritative simulation time.
7. Existing deterministic Stage 1 / Gates A–D core remains unchanged for R5.1.

## Proposed parameters requiring later tuning (NOT separately owner-locked)

- **Three machine aisles + one dedicated pantry stop**, with a working target of four machines per aisle (12 across the expanded arcade). The current Stage 1 retains M01–M04 in the Front Aisle only.
- More than four visible machines per aisle should require special viewport composition/proof; potential 3–6 range remains exploratory.
- Brief camera transition ~0.20–0.35s (to validate against pressure, control readability and art perspective).
- Offscreen alert or notification navigation is an *idea*, not an authorization for remote service or magical resupply.
- Pantry storage capacity, replenishment schedules, upgrade prices, travel timing and request/deadline balancing are deferred to gameplay design/testing.

## Mini-Pantry role and invariants

- Store a small finite selection of ready-to-use stock from the Workshop or other authored sources.
- Transfer exact item instances atomically to cart slots; no item creation, teleportation or duplicate stock.
- Limited card stock, gift supplies, and pre-prepared cassette reserves may become available through explicit upgrade and inventory rules.
- Full cassette prep, bulk card charging, trade-ups and complete gift wrapping remain Workshop-specific unless a future owner-approved change specifies otherwise.
- Services must remain reasonably completable without a premium upgrade/paywall; upgrades primarily reduce unnecessary travel.

## Living world and composition rules

- The room environment plate contains *architecture*, flooring, ceiling, signs and non-gameplay décor only.
- Every visible playable prize machine is an independent Godot scene with separate state, stock, geometry, mechanism, effects and service interaction; do not paint functional cabinet rows into the base plate.
- Customers can browse, queue, walk, chat, spectate, react, play, hold an actual won prize and leave. Near/far actor scaling and occlusion must be grounded in a consistent aisle layout.
- Speech/order bubbles are shown only for actionable stage-authored requests, never every customer.
- Aisle-switch rendering must restore the current authoritative tick and entity state without resetting offscreen animation/simulation.
- Keep HUD, interaction regions, navigation and service cart readable at 1280×720 in real Godot captures.

## Phased implementation implications

- **R5.1:** prove one clean Front Aisle composition and an independent high-fidelity M01 cabinet. Do NOT prematurely populate every aisle or implement pantry logic.
- **R5.2:** prove one genuinely animated actor can travel between depth zones without cutout sliding.
- **R5.3:** complete and demonstrate the functional M01 play/reward/failure/restock loop with synchronized actor actions.
- **Later:** expand to Central, Pantry and Rear only after the reusable building blocks are accepted. Pantry itself requires explicit scene, storage and balance tests.

## Acceptance

This document records a **navigation decision**, not visual approval or a completed implementation. R5.1 remains blocked until independently authored environment/M01 layers are integrated and accepted using genuine Godot captures. Preserve original simulation while testing.
