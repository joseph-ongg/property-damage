#!/usr/bin/env bash
# PR #18: reproducible local checks and cross-owner integration checks.
# Does NOT merge, force-push, switch branches or modify remote repositories.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

MODE="${1:---local}"
case "$MODE" in --local|--menu|--branch-report) ;; *)
    echo "Usage: $0 [--local|--menu|--branch-report]" >&2
    echo "  --local          Import and run 24 focused tests (PR #18 alone)" >&2
    echo "  --menu           Run Angela menu -> Garden E2E integration test (requires a combined checkout AND corrected menu destination)" >&2
    echo "  --branch-report  Report exact remote SHAs and Git merge conflicts, without changing branches" >&2
    exit 2 ;;
esac

if [[ "$MODE" == "--branch-report" ]]; then
    printf 'PR18_HEAD %s\n' "$(git rev-parse HEAD)"
    branches=(origin/angela/map-select-v2 origin/austin/items origin/eva-hp origin/ethan/fan-wind origin/sim/jackson/environment-burning)
    for branch in "${branches[@]}"; do
        if ! git rev-parse --verify -q "$branch^{commit}" >/dev/null; then
            printf 'BRANCH %s MISSING (fetch manually)\n' "$branch"
            continue
        fi
        sha="$(git rev-parse "$branch")"
        report="$(mktemp)"
        if git merge-tree --write-tree HEAD "$branch" >"$report" 2>&1; then
            printf 'BRANCH %s SHA=%s MERGE=CLEAN conflicts=0\n' "$branch" "$sha"
        else
            count="$(grep -c '^CONFLICT' "$report" || true)"
            printf 'BRANCH %s SHA=%s MERGE=CONFLICT conflicts=%s\n' "$branch" "$sha" "$count"
            grep '^CONFLICT' "$report" | head -5 || true
        fi
        rm -f "$report"
    done
    exit 0
fi

if [[ -n "${GODOT_BIN:-}" ]]; then
    GODOT="$GODOT_BIN"
elif command -v Godot >/dev/null 2>&1; then
    GODOT="$(command -v Godot)"
elif [[ -x "$ROOT/../Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT="$ROOT/../Godot.app/Contents/MacOS/Godot"
else
    echo "Godot not found. Set GODOT_BIN to its executable path." >&2
    exit 2
fi

LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pr18-acceptance.XXXXXX")"
printf 'PROJECT_ROOT=%s\nTEST_MODE=%s\nLOG_DIR=%s\n' "$ROOT" "$MODE" "$LOG_DIR"
echo "Importing Godot resources before testing (required on a fresh checkout)"
if ! "$GODOT" --headless --editor --path "$ROOT" --import --quit >"$LOG_DIR/import.log" 2>&1; then
    echo "Godot import FAILED; see $LOG_DIR/import.log" >&2
    exit 1
fi
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$LOG_DIR/import.log"; then
    echo "Godot import reported errors; see $LOG_DIR/import.log" >&2
    exit 1
fi

run_test() {
    local name="$1"
    local log="$LOG_DIR/$name.log"
    if ! "$GODOT" --headless --path "$ROOT" --script "res://gameplay/tests/$name.gd" >"$log" 2>&1; then
        echo "FAIL $name (non-zero exit); $log" >&2
        tail -25 "$log" >&2
        return 1
    fi
    if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:' "$log"; then
        echo "FAIL $name (engine/test errors); $log" >&2
        grep -E 'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:' "$log" | head -10 >&2
        return 1
    fi
    local summary
    summary="$(grep '_SUMMARY' "$log" | tail -1 || true)"
    if [[ -z "$summary" || "$summary" != *'failures=0'* ]]; then
        echo "FAIL $name (missing successful summary); $log" >&2
        tail -20 "$log" >&2
        return 1
    fi
    printf 'PASS %-50s %s\n' "$name" "$summary"
}

if [[ "$MODE" == "--menu" ]]; then
    if [[ ! -f "$ROOT/gameplay/MapSelection/map_select.tscn" ]]; then
        echo "Angela MapSelection not in checkout. This is INTEGRATION-ONLY." >&2
        exit 2
    fi
    run_test gameplay_garden_menu_e2e_integration_test
    echo 'MENU_HANDOFF_ACCEPTANCE PASS (does not include Angela final best-of-three scoreboard)'
    exit 0
fi

TESTS=(
gameplay_character_art_scope_test
gameplay_project_start_test
gameplay_smoke_test
gameplay_controls_test
gameplay_msd_test
gameplay_fan_direction_test
gameplay_render_layers_test
gameplay_simulation_contract_test
gameplay_upstream_grid_test
gameplay_magic_test
gameplay_platform_v2_test
gameplay_keyboard_chords_test
gameplay_art_handoff_test
gameplay_team_integration_test
gameplay_integration_merge_safety_test
gameplay_interaction_polish_test
gameplay_garden_design_contract_test
gameplay_garden_input_test
gameplay_garden_regression_edges_test
gameplay_garden_cross_branch_contract_test
gameplay_garden_round_handoff_test
gameplay_garden_attack_accounting_test
gameplay_garden_throwable_fire_test
gameplay_ninja_cross_arena_test
)
for name in "${TESTS[@]}"; do
    run_test "$name"
done
printf 'LOCAL_ACCEPTANCE PASS total=%d failed=0\n' "${#TESTS[@]}"
