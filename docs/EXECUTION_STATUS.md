# Gate A–D execution/acceptance record

Date: 2026-10-27 PDT (2026-10-28 UTC)

| Requirement | Status | Evidence |
| --- | --- | --- |
| 3 JSON schemas + 11 SKUs | Preflight PASS | `logs/schema_preflight.txt` |
| Stage references + ownership | Preflight PASS | `logs/schema_preflight.txt` |
| Mutated-invalid JSON rejected | Preflight PASS | `logs/schema_negative_checks.txt` |
| Stage command timeline coherency | Preflight PASS | `logs/replay_schedule_preflight.txt` |
| GDScript class/module presence | Static PASS | `logs/static_contract_check.txt` |
| Strict 4 + 2 + 1 cart | Static PASS | `logs/static_contract_check.txt`; Godot cases authored |
| Godot 4.7.2 source compilation/import | **UNVERIFIED** | Godot executable unavailable |
| 120 s, 7200-tick replay | **UNVERIFIED** | GDScript test authored, not executed |
| Same-state SHA256 across two replays | **UNVERIFIED** | GDScript test authored, not executed |
| Area changes cannot pause production | **UNVERIFIED** | GDScript test authored, not executed |
| Atomic failed admission and no double billing | **UNVERIFIED** | GDScript test authored, not executed |
| Exact 90-tick M02 reset and M03 miss stock return | **UNVERIFIED** | GDScript test authored, not executed |

Gate E is not authorized by this report. Accept Gates B–D only after running `tests/run_headless.sh` on Godot 4.7.2, resolving all GDScript parser and behavioral failures, and archiving the resulting `godot_headless.log`.
