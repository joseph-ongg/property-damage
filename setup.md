# Property Damage: Setup Guide

Goal: get the game running on your machine and push your first commit. About 15 minutes.

## 1. Install Godot 4.7.2 (standard, not .NET)

Everyone uses the **same version** so project files don't churn.

- Download **Godot 4.7.2-stable, Standard** from <https://godotengine.org/download/archive/4.7.2-stable/>
  - Do **not** pick the ".NET" / "C#" build. We use GDScript only.
- Windows: unzip anywhere (e.g. `C:\Godot\`) and run `Godot_v4.7.2-stable_win64.exe`. No installer.
- macOS: unzip, drag `Godot.app` to Applications. First launch: right click > Open.
- Linux: unzip, `chmod +x` the binary, run it.

Check: the Project Manager window title says **4.7.2.stable**.

## 2. Install Git and clone the repo

- Install Git: <https://git-scm.com/downloads> (macOS: `xcode-select --install` also works).
- Make sure you've accepted the invite to the GitHub repo.

```bash
git clone https://github.com/joseph-ongg/property-damage.git
cd property-damage
```

## 3. Open the project in Godot

1. In the Project Manager, click **Import**.
2. Browse to the `property-damage` folder and select `project.godot`.
3. Click **Import & Edit**.

The first open takes a minute while Godot builds its `.godot/` cache. That folder is gitignored; never commit it.

Check: the **Output** panel at the bottom shows no red errors.

## 4. Press F5

Press **F5** (macOS: **Cmd+B**) to run the game. A window should open saying *"Property Damage: it runs."* Close it.

If Godot asks you to pick a main scene, you opened the wrong folder. Go back to step 3.

## 5. Make a branch

Never commit straight to `main`. Name branches `yourname/what-you-are-doing`:

```bash
git checkout -b yourname/setup
```

## 6. Push one commit

Add your name to the roster below, then:

```bash
git add setup.md
git commit -m "Add <your name> to roster"
git push -u origin yourname/setup
```

Open the link Git prints to create a Pull Request, then post it in the team channel. Done.

## Project layout

| Folder | Owner | What goes here |
|---|---|---|
| `sim/` | Simulation & Systems | Materials sim: fire, oil, gas, collapse |
| `gameplay/` | Gameplay Programming | Fighters, input, combat, arena logic |
| `onboarding/` | Everyone | Tutorials, starter exercises, notes |

## Rules of thumb

- Pixel art: textures default to **Nearest** filtering (already set). Don't change it in Project Settings.
- Renderer is **Compatibility**, so it runs on older laptops. Don't switch it.
- If `project.godot` shows up in your diff and you didn't mean to change settings, don't commit it; ask first.

## Roster

- Joseph Ong
