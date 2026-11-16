#!/bin/zsh
# Launch the editor on THIS worktree, not the older project-damage checkout.
set -e
ROOT="${0:A:h}"
ENGINE="$ROOT/../Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$ENGINE" ]]; then ENGINE="/Applications/Godot.app/Contents/MacOS/Godot"; fi
if [[ ! -x "$ENGINE" ]]; then
  echo "Godot 4.7 not found. Import $ROOT/project.godot in Godot's Project Manager."
  read -k 1 "REPLY?Press any key to exit."
  exit 1
fi
cd "$ROOT"
echo "Opening project: $ROOT"
exec "$ENGINE" --editor --path "$ROOT"
