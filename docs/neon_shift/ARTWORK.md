# Artwork provenance and production briefs

## Preserved sources

The original `art/m01_v31` cabinet/gantry, `art/r5/front_aisle_architecture.png`, existing prize artwork and original project scenes remain unchanged. The new scene uses those registered components directly.

Actor 01's approved identity is copied byte-for-byte from the existing art branch into `art/neon_shift/actor01_identity.png`:

`dfc1312937313976179bf5cb830f088e79134eb9018fce09a468ed1b943e81e3`

Five recovered source walk PNGs are preserved without raster edits. Their original filenames, destination paths and hashes are recorded in `art/neon_shift/provenance.json`. They comprise corrected contact, mid-stride 1, passing, midstep 2 and opposite contact. These existing drawings are used as supplied, not claimed to be a newly approved animation set.

## New assets

New imagery is a candidate production extension for this development build. It does not replace the approved identity master or imply owner visual approval.

| Asset | Purpose | Production brief |
|---|---|---|
| `service_cart.png` | Foreground interactive cart | Detailed plum/chrome arcade cart; exactly four small supply bins, two larger prize bins and one bulk cradle; empty compartments, transparent background, consistent shallow perspective. |
| `sources/mika_reactions.png` | Actor 01 service reactions | Preserve bunny-hoodie identity; six isolated full-body poses for playing, anticipation, cheering, disappointment, holding a won plush, and showing a game card; 3×2 transparent atlas. |
| `sources/ren_poses.png` | Additional guest | Chibi male guest with dark hair, glasses, black hoodie and dark trousers; idle, four walking steps, playing, cheering, holding prize; 4×2 transparent atlas. A first opaque-background result was rejected; the delivered source uses corrected transparency. |
| `sources/yuki_poses.png` | Additional guest | Chibi woman with long dark-purple hair, dark jacket, pleated skirt and sneakers; same eight-pose grid and arcade illustration finish as Ren. |
| `sources/prep_equipment.png` | Interactive bench equipment | Three independent plum/chrome desktop stations: card charging docks, glass mochi refill hopper and gift-wrapping counter; blank display surfaces receive live progress overlays. |
| `sources/service_props.png` | Readable service objects | Six separated items: blue star game card, clear pink mochi cassette, cream gift with pink bow, ribbon, staff keys, collectible prize box; 3×2 transparent atlas. |

The above are production briefs, not a verbatim generation transcript. Equipment and props are generated illustrations; no claim of mechanical registration is made beyond measured display regions and real in-engine inspection.

## Registration

`tools/register_neon_art.py` measures visible alpha at a threshold of 32/255 and retains a two-pixel gutter. It writes only JSON display regions; PNG bytes remain unchanged. This avoids nearly transparent generator residue changing character scale or queue portrait crops. `ci/audit_neon_assets.py` verifies hashes, RGBA format, grid size and bounds.

Walk frames are scaled to a consistent visible height and foot line at runtime, then moved along perspective paths. This provides multi-frame movement, but drawing-to-drawing silhouette and pose differences remain. Further hand-directed in-between drawings are required for final animation quality.

## Audio and typography

`tools/create_neon_audio.py` generates an original deterministic eight-bar bell/chord score and four service cues from waveforms. No sampled commercial music is used. Source code permits reproducible regeneration.

Interface typefaces are DejaVu Sans and DejaVu Sans Bold. Their license and copyright notices are included at `art/neon_shift/fonts/LICENSE.txt`.
