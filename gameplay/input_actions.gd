## Registers isolated per-player actions. No project.godot Input Map edits needed.
extends RefCounted


static func register_actions() -> void:
	_ensure("p1_left", KEY_A)
	_ensure("p1_right", KEY_D)
	_ensure("p1_jump", KEY_W)
	_ensure("p1_down", KEY_S)  # Austin a529274: 穿过单向平台，S+W
	_ensure("p1_spark", KEY_F)
	_ensure("p1_interact", KEY_E)
	_ensure("p1_attack", KEY_G)
	_ensure("p1_dash", KEY_Q)
	_ensure("p2_left", KEY_LEFT)
	_ensure("p2_right", KEY_RIGHT)
	_ensure("p2_jump", KEY_UP)
	_ensure("p2_down", KEY_DOWN)  # 同一个功能，P2 用 ↓+↑
	_ensure("p2_spark", KEY_ENTER)
	_ensure("p2_interact", KEY_SHIFT)
	_ensure("p2_attack", KEY_PERIOD)
	_ensure("p2_dash", KEY_SLASH)


static func _ensure(action: StringName, key_code: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var input_event := InputEventKey.new()
	input_event.physical_keycode = key_code
	if not InputMap.action_has_event(action, input_event):
		InputMap.action_add_event(action, input_event)
