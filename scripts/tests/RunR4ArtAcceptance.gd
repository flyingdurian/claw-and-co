extends SceneTree
## Deliberately strict. Will not pass until actual separately illustrated rigs are supplied.
const RIG = preload("res://scripts/presentation/ArticulatedCustomerRig.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var failures: Array = []
    for i in range(1,11):
        var directory: String = "res://art/performers/actor_%02d" % i
        if not RIG.art_complete(directory): failures.append(directory)
    print("R4_ART_RIGS_PRESENT=",10-failures.size(),"/10")
    if not failures.is_empty():
        printerr("R4_ART_ACCEPTANCE_BLOCKED: Missing original modular sprite rigs: ", failures)
    else:
        print("R4_ART_RIG_CONTRACT_PASS (visual review still required)")
    quit(0 if failures.is_empty() else 1)
