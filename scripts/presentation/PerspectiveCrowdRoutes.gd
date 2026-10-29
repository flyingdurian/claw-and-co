class_name PerspectiveCrowdRoutes
extends RefCounted
## Deterministic perspective lane choreography. Inputs are ticks and explicit per-patron IDs.
## No gameplay RNG, no gameplay mutations, no offscreen spawning shortcuts.
const LANE_LEFT := [
    Vector2(58, 262), Vector2(69, 303), Vector2(90, 352),
    Vector2(118, 410), Vector2(177, 477), Vector2(260, 507),
    Vector2(360, 514), Vector2(430, 513), Vector2(515, 517)
]
const LANE_RIGHT := [
    Vector2(1243, 260), Vector2(1224, 300), Vector2(1215, 360),
    Vector2(1201, 411), Vector2(1150, 470), Vector2(1090, 504),
    Vector2(1010, 520), Vector2(920, 515), Vector2(810, 519)
]
const LANE_FRONT := [
    Vector2(160, 517), Vector2(300, 522), Vector2(480, 530),
    Vector2(630, 532), Vector2(800, 533), Vector2(1010, 530),
    Vector2(1210, 520)
]

static func depth_for_y(y: float) -> float:
    return clampf((y - 245.0) / 295.0, 0.0, 1.0)

static func sprite_scale(y: float) -> float:
    # 5:1 apparent size variation, unlike R3's nearly constant scale.
    var depth: float = depth_for_y(y)
    return lerpf(0.16, 0.84, pow(depth, 1.18))

static func _ease(u: float) -> float:
    var t: float = clampf(u, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)

static func route_point(route: Array, t: float) -> Vector2:
    assert(route.size() > 1)
    var scaled: float = clampf(t, 0.0, 1.0) * float(route.size()-1)
    var idx: int = mini(int(scaled), route.size()-2)
    return (route[idx] as Vector2).lerp(route[idx+1] as Vector2, _ease(scaled-float(idx)))

static func ambient_pose(tick: int, patron_index: int) -> Dictionary:
    # Each authored cycle approaches from behind the aisles, browses, watches,
    # chats or cheers near the floor, and departs to the rear of the arcade.
    var period: int = 1320 + (patron_index % 3) * 170
    var offset: int = (patron_index * 113) % period
    var u: float = float(posmod(tick + offset, period)) / float(period)
    var lane: Array = LANE_LEFT if patron_index % 2 == 0 else LANE_RIGHT
    var p: Vector2
    var action: String = "WALK"
    if u < .39:
        p = route_point(lane, u / .39)
    elif u < .49:
        p = lane[lane.size()-1]
        action = "WATCH" if patron_index % 3 == 0 else "CHAT"
    elif u < .70:
        p = route_point(LANE_FRONT, (u-.49)/.21) if patron_index % 2 == 0 else route_point(LANE_FRONT, 1.0-(u-.49)/.21)
    elif u < .82:
        p = lane[lane.size()-1].lerp(Vector2(875 if patron_index%2==0 else 370, 521), .6)
        action = "CHAT" if patron_index%2==0 else "WATCH"
    else:
        p = route_point(lane, 1.0-(u-.82)/.18)
    return {"position":p, "action":action, "scale":sprite_scale(p.y), "depth":depth_for_y(p.y), "near":p.y >= 451.0}

static func approach(start: Vector2, goal: Vector2, progress: float) -> Dictionary:
    var p: Vector2 = start.lerp(goal, _ease(progress))
    return {"position": p, "scale":sprite_scale(p.y), "near":p.y >= 451.0}
