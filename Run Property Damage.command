#!/bin/zsh
# Always use live source so this launcher cannot pick up an older export pack.
set -e
ROOT="${0:A:h}"
ENGINE="$ROOT/../Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$ENGINE" ]]; then ENGINE="/Applications/Godot.app/Contents/MacOS/Godot"; fi
if [[ ! -x "$ENGINE" ]]; then
  echo "Godot 4.7 not found. Import $ROOT/project.godot in Godot."
  read -k 1 "REPLY?Press any key to exit."
  exit 1
fi
cd "$ROOT"
echo "Launching live Property Damage from $ROOT"
exec "$ENGINE" --path "$ROOT" --windowed
