CLAW & CO. R4.1 - Godot 4.7.2 parser collision fix
Status: STATIC PATCH VERIFIED; GODOT EXECUTION NOT AVAILABLE HERE.

Issue reproduced from packaged source:
scripts/core/InventoryLedger.gd:35 declares
    func set_meta(instance_id: String, key: String, value: Variant) -> bool:
which conflicts with inherited Object.set_meta(StringName, Variant) -> void.

Fix:
  InventoryLedger.gd:35   set_meta -> set_item_metadata
  WorkshopManager.gd:84 ledger.set_meta -> ledger.set_item_metadata

The method body, transactions, game stage, assets, and other preexisting files
are unchanged. Godot parser and game tests MUST be run in the player's installation.
