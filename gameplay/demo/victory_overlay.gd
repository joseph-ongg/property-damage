## Separate result presentation layer; no change to the scoring or arena logic.
extends CanvasLayer


func _ready() -> void:
	visible = false


func show_result(shards_p1: int, shards_p2: int, duo_combos: int) -> void:
	$Backdrop/Subtitle.text = "5 EMBER SHARDS    •    3 ANCIENT BRAZIERS"
	$Backdrop/Stats.text = "P1: %d    P2: %d     DUO SPARK COMBOS: %d" % [shards_p1, shards_p2, duo_combos]
	visible = true
