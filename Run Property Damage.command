#!/bin/zsh
# Launch the locally exported Godot pack using the Godot 4.7 Mac app.
# This helper does not require any extra package manager or network calls.
set -e
ROOT="${0:A:h}"
ENGINE="$ROOT/../Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$ENGINE" ]]; then
  ENGINE="/Applications/Godot.app/Contents/MacOS/Godot"
fi
if [[ ! -x "$ENGINE" ]]; then
  echo "Godot 4.7 Standard not found. Open project.godot using Godot 4.7 and press F5."
  read -k 1 "REPLY?Press any key to finish."
  exit 1
fi
cd "$ROOT"
if [[ -f build/PropertyDamage.pck ]]; then
  exec "$ENGINE" --main-pack "$ROOT/build/PropertyDamage.pck" --windowed
else
  exec "$ENGINE" --path "$ROOT" --windowed
fi
