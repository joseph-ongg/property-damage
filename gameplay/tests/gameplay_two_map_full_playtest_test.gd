## The playtest adapter is deliberately not the team's release branch.
## Real menus, real key inputs, both existing arenas, actual Health and KO,
## round handoff, user-driven playtest completion, and map switching.
extends SceneTree

var failures: Array[String] = []
var observed_round_winners: Array[int] = []
var observed_completed_sessions: Array[int] = []

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, message: String) -> void:
    print(("PASS: " if condition else "FAIL: ") + message)
    if not condition:
        failures.append(message)

func frames(n: int) -> void:
    for _i in n:
        await physics_frame

func press_key(code: Key, down: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = down
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func shoot(code: Key) -> void:
    press_key(code, true)
    await frames(2)
    press_key(code, false)
    await frames(75) # comfortable buffer beyond Eva's 0.8s i-frame, including windowed Godot

func get_button(panel: Node, which: String) -> Button:
    for child in panel.get_children():
        if child is Button and child.text.begins_with(which):
            return child
    return null

func combat_lane(app: Node2D) -> void:
    var p1 := app.arena.get_node("Player1") as GameplayPlayer
    var p2 := app.arena.get_node("Player2") as GameplayPlayer
    if app.selected_map == "res://gameplay/garden/garden_level.tscn":
        # This lane leaves the Garden hose nozzle (at x580) untouched.
        # Austin's newly merged item hitboxes correctly block spells, so
        # deterministic pure-PvP assertions use the unobstructed right side.
        p1.global_position = Vector2(710,455)
        p2.global_position = Vector2(800,455)
    else:
        p1.global_position = Vector2(430,468)
        p2.global_position = Vector2(520,468)
    p1.velocity = Vector2.ZERO
    p2.velocity = Vector2.ZERO
    p1.facing = 1
    p2.facing = -1
    await frames(6)

func play_round(app: Node2D, attacker: int, label: String) -> void:
    await combat_lane(app)
    var key := KEY_G if attacker == 1 else KEY_PERIOD
    var victim := app.arena.get_node("Player%d" % (3 - attacker)) as GameplayPlayer
    var original := victim.health_component.hp
    for n in range(12):
        await shoot(key)
        if n == 0:
            check(victim.health_component.hp == original - 10,
                label + ": real physical key applies 10 PvP damage")
    check(victim.health_component.hp == 0, label + ": 12 hits reach 0 HP")
    check(app.round_over, label + ": round ends automatically")
    check(not app.arena.get_node("Player1").is_physics_processing() and
        not app.arena.get_node("Player2").is_physics_processing(),
        label + ": KO freezes both controllers")
    check(victim.get_node("NameTag").text == "KO",
        label + ": loser has visible KO state")

func start_map(app: Node2D, map_name: String) -> void:
    check(app.screen_mode == "map", map_name + ": selector displayed")
    var menu: Control = app.screen.get_node("AngelasMapSelect") as Control
    # Angela's authored selector now includes a title label; count only
    # actual map buttons, not ornamental or navigation controls.
    var buttons: Array[Node] = []
    for candidate in menu.get_node("CenterContainer/VBoxContainer").get_children():
        if candidate is Button and candidate.text in ["Living Room", "Garden"]:
            buttons.append(candidate)
    check(buttons.size() == 2, map_name + ": Angela selector has exactly two maps")
    var chosen: Button = buttons[0] if map_name == "Living Room" else buttons[1]
    check(chosen.text == map_name, map_name + ": correct source button")
    chosen.pressed.emit()
    await frames(12)
    check(app.screen_mode == "fight" and app.arena != null,
        map_name + ": real selector button opens working game")
    check(app.arena.name == ("GameplayMSD" if map_name == "Living Room" else "Garden"),
        map_name + ": correct real arena loaded")

func play_two_rounds(app: Node2D, winner: int, map_name: String) -> void:
    await play_round(app, winner, map_name + " round 1")
    check(app.scores[winner] == 1, map_name + ": first round recorded (not final match score)")
    if not app.screen.has_node("ResultPanel"):
        check(false, map_name + ": missing KO/round result panel after real PvP")
        quit(2)
        return
    var next: Button = get_button(app.screen.get_node("ResultPanel"), "Next round")
    check(next != null, map_name + ": Next Round button visible")
    next.pressed.emit()
    await frames(8)
    check(app.round_number == 2 and not app.round_over, map_name + ": next round starts")
    check(app.arena.get_node("Player1").health_component.is_alive() and
        app.arena.get_node("Player2").health_component.is_alive(),
        map_name + ": both players revived after next round")
    await play_round(app, winner, map_name + " round 2")
    check(app.scores[winner] == 2 and not app.screen_mode == "summary",
        map_name + ": two won rounds DO NOT auto-decide a final match winner")
    var finish: Button = get_button(app.screen.get_node("ResultPanel"), "Finish playtest")
    check(finish != null, map_name + ": user may finish without a match winner rule")
    finish.pressed.emit()
    await frames(4)
    check(app.screen_mode == "summary" and app.arena == null,
        map_name + ": explicit Finish button opens session summary")
    var summary: VBoxContainer = app.screen.get_node("MenuStack") as VBoxContainer
    var has_disclaimer := false
    for child in summary.get_children():
        if child is Label and child.text.contains("waiting for Design specs"):
            has_disclaimer = true
    check(has_disclaimer, map_name + ": completion states no official match winner")

func _run() -> void:
    var app := (load("res://gameplay/integration/two_map_playtest/two_map_playtest.tscn") as PackedScene).instantiate()
    root.add_child(app)
    current_scene = app
    await frames(7)
    app.round_ended.connect(func(index: int) -> void:
        observed_round_winners.append(index))
    app.playtest_ended.connect(func(rounds_played: int) -> void:
        observed_completed_sessions.append(rounds_played))
    check(app.screen_mode == "character", "F5 entry starts at character selection")
    var stack: VBoxContainer = app.screen.get_node("MenuStack") as VBoxContainer
    var one := stack.get_node("P1Choice") as OptionButton
    var two := stack.get_node("P2Choice") as OptionButton
    check(one.item_count == 3 and two.item_count == 3,
        "Both players can choose only Design's three named characters")
    one.select(0)
    two.select(0)
    get_button(stack, "Choose one").pressed.emit()
    await frames(5)

    await start_map(app,"Living Room")
    await play_two_rounds(app,1,"Living Room")
    check(observed_round_winners == [1,1] and observed_completed_sessions == [2],
        "Living Room records rounds and only ends session when user requests")
    if not app.screen.has_node("MenuStack"):
        print("E2E_ABORT: no Living Room session summary")
        quit(2)
        return
    var rematch := get_button(app.screen.get_node("MenuStack"),"Restart playtest")
    rematch.pressed.emit()
    await frames(7)
    check(app.round_number == 1 and app.scores[1] == 0 and app.scores[2] == 0,
        "Real Restart Playtest button resets round records and positions")
    await combat_lane(app)
    await shoot(KEY_G)
    check(app.arena.get_node("Player2").health_component.hp == 110,
        "Living Room rematch still deals real PvP damage")
    # No forced official game changes: transition between experiment stages is
    # an adapter UI operation, while map selection comes from Angela's scene.
    var leave: Button = app.screen.get_node("QuitToMaps") as Button
    check(leave != null, "Living Room session has real midmatch Return to Maps control")
    leave.pressed.emit()
    await frames(7)
    await start_map(app,"Garden")
    await play_two_rounds(app,2,"Garden")
    check(observed_round_winners == [1,1,2,2] and observed_completed_sessions == [2,2],
        "Both arenas finish only when user requests, without a match winner rule")
    var go_back := get_button(app.screen.get_node("MenuStack"),"Back to map")
    go_back.pressed.emit()
    await frames(5)
    check(app.screen_mode == "map" and app.arena == null,
        "Actual end-match Back to Map button returns to map selector")
    app.screen.get_node("BackToCharacters").pressed.emit()
    await frames(3)
    check(app.screen_mode == "character", "Back to character selection works")

    # Verify selections propagate Design-provided HP scales.
    stack = app.screen.get_node("MenuStack")
    one = stack.get_node("P1Choice") as OptionButton
    two = stack.get_node("P2Choice") as OptionButton
    one.select(1)
    two.select(2)
    get_button(stack,"Choose one").pressed.emit()
    await frames(3)
    await start_map(app,"Garden")
    check(app.arena.get_node("Player1").health_component.max_hp == 100 and
        app.arena.get_node("Player2").health_component.max_hp == 160,
        "Ninja 100 HP and Werewolf 160 HP propagate through real selection")
    check(app.arena.get_node("Player1").character_kind == "ninja" and
        app.arena.get_node("Player2").character_kind == "werewolf",
        "Existing character visuals/stats are selected; no invented attack")
    app._show_characters()
    await frames(2)
    check(app.arena == null, "Exiting playtest frees active arena")
    for issue in failures:
        print("PLAYTEST_KNOWN_ISSUE: " + issue)
    print("TWO_MAP_FULL_PLAYTEST_SUMMARY failures=%d winners=%s" % [
        failures.size(),str(observed_round_winners)])
    quit(0 if failures.is_empty() else 2)
