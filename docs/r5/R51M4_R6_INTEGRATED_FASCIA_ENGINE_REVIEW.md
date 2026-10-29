# CLAW & CO. — R5.1-M4 R5/R6 Integrated Fascia Review

Reviewed on 2026-10-29 Vancouver. Test SHA `473c9fb73b93e18572441d0a1aead0e92e8b2529`.

## Source and actual evidence
[Godot 4.7.2 mechanical proof run](https://github.com/flyingdurian/claw-and-co/actions/runs/40972559168).
- **1121/1121** assertions passed, zero failed.
- Actual 9 Godot 1280×720 screenshot frames and 12-second Godot movie produced.
- All existing core deterministic Stage 1 simulation, managers, money, stock, and accepted tests unchanged.

## Implemented since R4
**R5**: Removed rear roof-cap illustration duplicates, preserved only near/fascia roof attachment plates; front mounting bracket art enlarged and rear brackets made subordinate. Both stationary crossmembers were made visually subordinate to the painted original roof trim.
**R6**: Increased both guide rail structural widths (rear 30 px, front 38 px in original M01 cabinet canvas). Reused the approved cabinet's existing illustrated front roof as the near load-bearing crossmember instead of re-painting an additional translucent metal bar over it. Rear crossmember remains lightly visible under fascia. Bridge endpoints still derive from fixed rail constraints, the motor/cable remain moving independently.

## Visual findings
Direct image crop comparison R4→R5→R6 demonstrates **only a modest, local reduction in duplicate ceiling detail**. A 335×125 crop of the same Godot shot showed mean per-channel absolute image difference of ~8.2 pixels from R4 to R6 (5 to R6 ~2.08). These values quantify change, **not fidelity**.
The roof rail hardware, perspective and physical mount still require high-fidelity review: in zoomed Godot frames one can trace the moving trolley and cable; however the right support/pink hardware still has a cluttered small-fragment visual. No visual breakthrough sufficient to accept R5.1-M4.

## Decision
**Mechanics pass; visual composition remains NOT ACCEPTED.**
Do not escalate to working prize-grip outcome or mark the whole game ready on the strength of 1121 assertions. PR #1 stays draft.

## Recommended next design step
Purely cosmetic crossmember stacking has reached diminishing returns. Next fix must change how the fixed roof geometry is authored, not add small pieces:
- Establish physically coherent back/near rail planes from original cabinet geometry, then texture-map custom rails/supports with stronger camera-correct silhouette.
- Use already approved donor chrome artwork where legible, rather than asking Astra again to place exact pixels.
- Prefer a new *isolated ceiling cutaway/roof geometry fixture* that can be judged before reattaching prize art and the full environment.
- Require actual Godot image/video under no-UI proof, plus explicit owner approval once an independently compelling composition exists.
- Do not alter accepted Stage 1 gameplay, stock, scoring or customer transactions during this proof.

This report closes R5/R6 engineering comparison, **not** M4 visual acceptance.
