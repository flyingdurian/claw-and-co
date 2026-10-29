class_name SimulationClock
extends RefCounted
## Headless: call step() exactly 7200 times. Live: invoke step() from _physics_process.
var tick: int = 0
const HZ: int = 60
const STAGE_TICKS: int = 7200
var paused: bool = false

func step() -> int:
    if not paused and tick < STAGE_TICKS: tick += 1
    return tick

func seconds_elapsed() -> float:
    return float(tick) / float(HZ)
