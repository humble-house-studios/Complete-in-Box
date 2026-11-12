# Complete In Box — read before every change

A roguelike about collecting and flipping retro games: Balatro/CloverPit
structure where your **shelf is the hand**. Each ante has three stops (The Hunt,
The Shop, Online); at each one you buy, haggle, dig, sell, list and grade, then
your shelf is appraised (items = chips, sets and perks = Mult) against a rising
target. More venues and rarer collectibles unlock as the run goes on.
Godot 4.3, GDScript only. Parody names on purpose (no real brands).

Samuel builds from his phone: Claude writes and pushes the code, GitHub builds a
web version, and he playtests it in Safari. Keep replies short and in plain words,
and handle git, builds and fixes yourself.
**End every reply with the play link:** https://humble-house-studios.github.io/complete-in-box/

## The scaling rule
The web build in Safari is the test for every platform.
- **Phones = vertical. Steam = horizontal.** Base 720×1280, stretch
  `canvas_items`, aspect `expand`; `game.gd` swaps the base to 1280×720 when the
  screen is wider than tall. Portrait = one column, landscape = two columns.
- Mobile exports lock to portrait; desktop opens a 1280×720 window.
- Build UI from Control nodes and containers, never fixed pixel positions.
- Compatibility renderer everywhere. Nothing web-only (wrap platform code in
  `OS.has_feature(...)` with a fallback). Touch and mouse both work; touch
  targets at least 88 px tall at 720 wide. Respect the safe area
  (`scripts/ui/safe_area.gd` + `cibSafeInsets` in `export_presets.cfg`).
- Stay light: web build under ~30 MB, no threads.

## Code structure
- `scripts/data/` — `catalog.gd` (every item, platform, condition),
  `venues.gd` (the stops, their rules, boss twists), `perks.gd` (perks + upgrades).
- `scripts/engine/` — `run.gd` (all rules, no UI; actions return
  `{ok, msg}`), `balance.gd` (every tuning number: targets, rewards, odds).
- `scripts/ui/game.gd` — the whole UI, rebuilt from the run's state after each
  action. `DEV` = dev buttons at Home; set false before shipping.
  `sfx.gd` = synthesized sound effects (no audio files).
- Placeholder art only: colored panels and labels. No image generation.
- Ask before adding any addon beyond GUT.

## Testing pipeline
- Tests: `godot --headless -s addons/gut/gut_cmdln.gd` (run in CI before every
  build; a failing test or script error blocks the deploy).
- Balance: `godot --headless -s res://tools/sim.gd` — a greedy bot plays 300
  runs and prints where they die. CI shows it as a notice. A good human should
  beat the bot comfortably.
- Screenshots: `xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/screenshot.gd -- OUT_DIR [landscape]`.
- After each change: push to `main`, wait for the build to pass (fix it if it
  doesn't), then send Samuel the play link with one line on what changed and
  what to playtest.
