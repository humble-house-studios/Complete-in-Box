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
**End every reply with the play link:** https://humble-house-studios.github.io/Complete-in-Box/

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
  `sfx.gd` = sound effects (real recordings, random takes), music per venue
  type with crossfades, room ambience; synth fallback if a file is missing.
- `scripts/gfx/` — the look. `stage.gd` = the low-res PSX 3D room behind the UI
  (one per venue + title/home/appraisal, items on the table, flickering bulbs,
  dither post shader); `item_models.gd` = a 3D model for every catalog item
  (real cart models + per-game labels, jewel cases, boxes, consoles, pads);
  `psx.gd` = shared PSX material + prop loader. Shaders in `assets/shaders/`.
- Ask before adding any addon beyond GUT.

## Art + sound
- CloverPit-style look, bright pass: lived-in rooms with windows/doors onto
  real 3D outdoors (streets, houses, cars, trees, skyline), shopkeepers and
  shoppers, posters of item box art, sun with hard shadows. PSX vertex snap,
  nearest 256 px textures, 1/2-res render with light dither, soft CRT overlay,
  chunky Jersey fonts, juicy counters.
- Props: `assets/models/props/` (Kenney furniture) plus kit folders `car/`,
  `suburb/`, `shop/`, `urban/`, `city/`, `nature/` — load as `Psx.prop("shop/cash-register", h)`.
  Preview a folder: `xvfb-run ... -s res://tools/prop_sheet.gd -- OUT_DIR shop`.
- The UI leaves a see-through gap under the header (`_stage_gap`) and aims the
  3D camera at it (`_update_focus`). Panels are smoked glass (alpha ~0.9).
- Item art is baked, not drawn at runtime: after changing `catalog.gd` or
  `item_models.gd`, run
  `xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 -s res://tools/bake_items.gd`
  then `godot --headless --import`. It writes `assets/items/labels/` (box art)
  and `assets/items/icons/` (card renders).
- Check rooms: `xvfb-run ... -s res://tools/stage_shots.gd -- OUT_DIR [landscape]`.
- Headless runs skip building the 3D stage (no renderer), so tests stay fast.

## Assets
- Grab any asset Samuel asks for from anywhere, using `tools/grab.sh <url> <dest_folder>`
  (direct files/archives or OpenGameArt pages; keeps usable files, converts
  audio to .ogg and 3D to .glb). Needs assimp-utils, p7zip-full, ffmpeg, unzip.
- Always log the source URL in `assets/sources.txt` (`path | url | date`;
  grab.sh does it). Don't worry about licenses.
- After adding assets, run a headless import and fix or report any errors:
  `godot --headless --import`
- Folders: `assets/{audio/sfx,audio/music,models/props,models/items,textures,fonts,items,shaders}`.
  Keep it light: textures 128 px, audio mono ogg. Anything over ~10 MB goes
  through Git LFS, and then the deploy checkout needs `lfs: true`.
- Blocked from cloud sessions: kenney.nl (403), poly.pizza (Cloudflare).
  OpenGameArt mirrors most Kenney packs; ambientCG and Google Fonts (via
  raw.githubusercontent.com/google/fonts) work.

## Testing pipeline
- Tests: `godot --headless -s addons/gut/gut_cmdln.gd` (run in CI before every
  build; a failing test or script error blocks the deploy).
- Balance: `godot --headless -s res://tools/sim.gd` — a greedy bot plays 300
  runs and prints where they die. CI shows it as a notice. A good human should
  beat the bot comfortably.
- Screenshots: `xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/screenshot.gd -- OUT_DIR [landscape]`.
  Use these to check the look after any visual change.
- After each change: push to `main`, wait for the build to pass (fix it if it
  doesn't), then send Samuel the play link with one line on what changed and
  what to playtest.
