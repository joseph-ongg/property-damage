## Small session-level handoff between Angela's map menu and Gameplay players.
## No project.godot autoload; empty/direct playtest keeps the original Mages.
extends RefCounted
class_name GameplayCharacterSelectionState

const KINDS: Array[String] = ["mage", "ninja", "werewolf"]
static var has_selection: bool = false
static var player1_kind: String = "mage"
static var player2_kind: String = "mage"


static func choose(p1: String, p2: String) -> bool:
	if not KINDS.has(p1) or not KINDS.has(p2):
		return false
	player1_kind = p1
	player2_kind = p2
	has_selection = true
	return true


static func for_player(player_number: int) -> String:
	return player2_kind if player_number == 2 else player1_kind


static func clear() -> void:
	player1_kind = "mage"
	player2_kind = "mage"
	has_selection = false
