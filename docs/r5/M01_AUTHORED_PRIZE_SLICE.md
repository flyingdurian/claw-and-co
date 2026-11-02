# CLAW & CO. — M01 gameplay presentation slice (isolated)
Base: approved M01 V3.1 rig and unmerged PR #2 head `d642bb756136028b60cf1d36d7d4ba034f60d2f8`.
Branch: `r5/m01-authored-prize-visual-slice`. No changes to deterministic simulation, charge/inventory transactions, exact-prize admission, 60 Hz ticking, or other cabinets.
Adds a registered M01 prize chamber and a single visible prize sprite that follows the actual cable endpoint **only** when an authored winning attempt and its exact inventory reservation both agree. The floor sprite is hidden for that exact instance while carried. Miss and mismatched reservations do not carry a prize; OUTPUT_HELD is taken exclusively from MachineManager state.
This is the first M01 integration slice, not full pickup collision/physics, claw strength or fully animated floor prize rigging. Keep PR #2 in draft until owner acceptance and merge it before considering this isolated branch for merge.
Proof: RunM01AuthoredPrizeTests.gd plus four real M01_Machine.tscn screenshot states captured in Godot.
