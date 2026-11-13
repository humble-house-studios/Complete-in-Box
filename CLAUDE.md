# Collector's Curse (repo: Complete In Box) — read before every change

A roguelike about collecting and flipping retro games: Balatro/CloverPit
structure where your **shelf is the hand**. Each ante has three stops (The Hunt,
The Shop, Online); at each one you buy, haggle, dig, sell, list and grade, then
your shelf is appraised (items = chips, sets and perks = Mult) against a rising
target. More venues and rarer collectibles unlock as the run goes on.
Godot 4.3, GDScript only. Parody names on purpose (no real brands).

## The curse (story)
Title is **Collector's Curse** (repo and URL keep the old name). CloverPit-style:
bright, funny surface, dread underneath. You inherit great-uncle Arlo's shelf and
his debt to the Buyer, `c0mplete_set`, whose appraiser scores every stop. Lore lives
in `Flavor.LETTERS` (one letter per ante, shown on the HOME PC when you get home at
stop 0: `_maybe_letter` / `_open_letter`, read count `Run.letters_read`; reread from
the route tab), `Flavor.EPILOGUE` (after winning), the how-to guide (THE INHERITANCE,
PAY THE APPRAISER, CHECK YOUR MAIL), appraiser PASS/FAIL lines, item histories and
`LOADING_TIPS`. Twist (letter 8): the Buyer is Arlo, graded 9.8, still in the plastic.
Losing = GRADED & SEALED: Stage scene `"cursed"` (`Stage._cursed`, `_grade_case`):
you (`Stage.PLAYER`) shrink-wrapped and tied with twine in a glass case on a plinth,
with a grading slab label (`Stage.case_info`), in a dark vault of other cased
collectors. Grade and condition come from `Run.curse_grade()` (how close you came).
Boss twists are shown as THE BUYER'S TERMS. Shots: `tools/curse_shots.gd`.
The twist stays hidden until your first loss: the title vault's corner case
(`Stage._vault_case`, `Stage.vault_case`) stands under a dust sheet with a RESERVED
plaque and a red glow under the hem (the intro flight glances past it); after a loss
the sheet is on the floor and your last sealed self is inside (save keys `sealed`,
`seal_grade`, `seal_cond`, `seal_ante`, `seal_lot`; `_vault_info`). The guide's PAY THE
APPRAISER page uses its `secret` lines until then.

## Replay: estates, grade tiers, binder rewards
All data in `scripts/data/unlocks.gd` (no class_name, preload as `Unlocks`).
- ESTATES = starting decks (Arlo, Aunt June, Cousin Dale, Grandma Rose, Uncle Hector,
  the Pruitt Twins): cash, starters (+cond, `damaged`), shelf, perks, perk_cap, interest,
  plus a first letter and loading line. A win frees the next sealed one (save `estates`
  bitmask). Picked in `_open_estates` (CHOOSE YOUR INHERITANCE) once there's a choice.
- TIERS = grade tiers 0..4 (9.0, 9.5, 9.8, 10, BLACK LABEL), cumulative: targets x1.2,
  -$10 start, Buyer's terms every stop (`Run.is_boss_stop`), -1 shelf and targets x1.45.
  Winning tier N opens N+1 (`max_tier`); `won_<estate>` = best tier beaten (card sticker).
- BINDER = owned-count milestones: perks with `"lock": "binder"` in perks.gd only enter
  the shop once unlocked (`Run.unlocked_perks`), +1 shelf, +$10; PAGE STAMPS (own half a
  platform's page) = +$1 start cash each. Toasts in `_check_binder_reward`.
- `Run.start(seed, opts)` takes estate / tier / perks_unlocked / bonus_cash / bonus_shelf
  (`_run_opts`). Win news on the won screen via `_record_win` / `_won_unlocks`.
- Sim: `godot --headless -s res://tools/sim.gd -- meta` = estates and tiers only. Keep
  estates within a few % of Arlo for the bot. Shots: `tools/meta_shots.gd`.

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
- Stay light: web build under ~30 MB (soft target for phone load time and
  iOS memory; up to ~50 MB is OK if it buys real quality), no threads.

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
- `perk_art.gd` = perk/upgrade card art: a themed background per perk (`THEMES`:
  sunrise, basement bricks, ocean, price list, synthwave...) + its 3D picture (`Subjects.PERKS`).
  `subjects.gd` and `perk_art.gd` have no class_name (TV self-update): preload them.
- Box art is painted at each box's real front shape (`Art.cover_size`: H 150, width
  from `ItemModels.GAME_BOX`; consoles 1.5, accessories 1.2; `BoxArt.W` varies).
  Pictures never stretch: cart stickers letterbox (`Psx.label_mat(..., aspect)`),
  discs/posters/quads crop (`Psx.fit`, `tex_fit`). Sizes are real (`REAL_*`): a loose
  CD is 12 cm, a mini disc 8 cm, a DS card 3.5 cm.
- Minor sheet actions (4th entry `true`, e.g. Hang on Wall) sit small beside Close.
- New offers get a slot-machine reveal (`scripts/ui/slot_reel.gd`, preload; `_slot_reel`):
  any offer uid not in `_spun` spins when it first appears (entering a stop, dig,
  back room), staggered, waits for the loading card, lands on its rarity, tap skips.
- Art load: on screen Art paints `LIVE_PER_FRAME` (4) per batch, 16 behind a loading
  card; icon renders skip the box back (`ItemModels.icon_build`). Binder tiles use
  `_lazy_icon` (requested only when scrolled into view) and `Art.forget_unwatched()`
  drops unstarted jobs when you flip pages or leave. Item card auto-spin is slow (0.14).
- Discs show their data side with a diffraction rainbow (`assets/shaders/disc_back.gdshader`,
  black on PST/PST2). F64 carts use a real N64-shell model (`n64Cartridge.glb`, from a
  Printables STL via `tools/stl_to_glb.py`; Printables' GraphQL API downloads STLs).
- Extra games come from `docs/research/retro_gaming_n64_more.txt` (own section, so the
  top-500 ranks stay put); `GENRE_EXACT` in gen_catalog.py sets their genres.
- MARKETS (cards + coins): after ante 4 the route offers THE CARD SHOPS, after ante 6 THE
  RARE COIN TRADE (`Run.pivot_offer/pivot`, `_pivot_panel`): sell the whole shelf at
  `Balance.PIVOT_RATE`, get starters + Time, and from then on `run.market` picks the
  platforms, venues (`"market"` in venues.gd) and decor. Lists: `docs/research/tcg_cards_top_250.txt`,
  `rare_coins_top_250.txt` -> `python3 tools/gen_collectibles.py` -> `scripts/data/catalog_cc.gd`
  (parody card names; edit the generator). Kinds card / pack / coin; condition words per hobby
  (`Catalog.cond_name`); packs can be ripped (`Run.open_pack`). Art: `scripts/gfx/cc_art.gd`
  (TCG frames, card backs, foil packs/boxes, embossed coins); models in `ItemModels._collectible`
  (top-loaders, slabs, 2x2 flips, capsules, proof cases). Rooms reuse shells with `Stage.SIGNS`,
  plus `_beach`. Check art: `art_sheet.gd -- OUT.png SEED cards|coins`.
- Ask before adding any addon beyond GUT.

## Art + sound
- CloverPit-style look, bright pass: lived-in rooms with windows/doors onto
  real 3D outdoors (streets, houses, cars, trees, skyline), shopkeepers and
  shoppers, posters of item box art, sun with hard shadows. PSX vertex snap,
  nearest 256 px textures, 1/2-res render with light dither, soft CRT overlay,
  chunky Jersey fonts, juicy counters.
- House style in 3D (ties rooms to the cards): items sit on a purple felt mat with
  gold trim and an orange front lip (`Stage._display_mat`, via `_lay_items`), rare and
  grail items get a pulsing ring in their tier colour (`_tier_glow`), items and people
  get an ink outline (`Psx.outline`, `assets/shaders/outline.gdshader`), warm dust
  motes drift in view (`_motes`), and `post.gdshader` grades shadows purple and
  highlights gold. Outlines and motes are off in `Lite.perf`.
- People: realistic Microsoft Rocketbox avatars (MIT), rigged (`tools/gen_people.sh CLONE GODOT`
  -> `tools/bake_people.gd` -> `assets/models/people_rb/<name>_rig.scn` + 256 px body/head
  textures), loaded with `Psx.person(name)` (hair cards alpha-cut). No animation clips:
  `Stage._pose` sets bones in code (arms down, walk cycle, chores: browse, reach,
  restock, wipe, talk). `_person(pos, rot, tint, h, who)` = standing; `_walker(path,
  acts, who, speed)` = walks the path in a loop, pausing to do `acts` (a name or
  [name, facing_deg]); walkers stand still in Lite.perf. Arcade machines in `props/arcade/`.
- LOOK AROUND (venue button, pause menu): `_room_view` hides the menus; `Stage.room_view`
  is an orbit camera round the room. `_on_room_input`: one finger / left drag orbits
  (`room_orbit`), pinch / wheel / trackpad zooms (`room_zoom_by`), two fingers / right or
  middle or shift-drag pans (`room_move`), double-tap resets (`room_reset`); on screen - / +
  / RESET buttons; pad: left stick orbit, right stick pan, LT/RT zoom, X reset, B back.
  Walk cycle: arms swing against the same-side leg, `ARM_IN` near 0 (+Z = back).
- The title vault: velvet plinth with gold rings and a GRAIL plaque, museum ropes, a
  light beam (`_beam`), stacks of real boxed games (`_box_stack`), arcade cabinets.
- Menus share one look: `_menu_card(icon, title, sub, col, cb, h, main, chip)` (a card
  with the thick coloured edge, a glossy icon from `Subjects.MENU`, title + line, arrow or
  chip) and `_menu_tile` (icon over label). Title = `_title_logo` (COLLECTOR'S / CURSE + AS-IS
  sticker + tagline pill), MAIN MENU panel (`_title_menu`: run card, collection card with
  WALL chip, tiles for how to play / sound / GFX / credits) and `_records_card`; landscape =
  logo + records left, vault middle, menu right. The sound gate and the pause menu
  (`_open_menu`: PAUSED + ANTE sticker, run card with cash and a shelf-vs-target bar,
  RESUME, view shelf / look around, setting tiles, quit) use the same pieces.
- Props: `assets/models/props/` (Kenney furniture) plus kit folders `car/`,
  `suburb/`, `shop/`, `urban/`, `city/`, `nature/` — load as `Psx.prop("shop/cash-register", h)`.
  Preview a folder: `xvfb-run ... -s res://tools/prop_sheet.gd -- OUT_DIR shop`.
- Cards and menus: coloured pills for tags (`_pill`), tilted price-gun
  stickers, platform-tinted cards with a thick left edge, sign-style section
  headers, light icon wells. Flavor text lives in `scripts/data/flavor.gd`
  (condition notes, seller quotes per venue, venue moods, appraiser quips);
  quoted lines render as speech panels in sheets. Keep body text >= 16 px.
- Menus are tabbed to stay uncluttered: Home = ROUTE / PERK SHOP / SHELF
  (landscape: route left, tabs right); venues on phones = FOR SALE / YOUR SHELF.
  Between stops the background is always your evening living room (moody
  lamps, your shelf lit, THE WALL case beside it with `Stage.wall_items`);
  the route card's postcard shows where you're headed. VIEW YOUR SHELF (route
  tab, shelf tab, pause menu) hides the menus and moves the camera to the
  shelves (`Stage.showcase`) with a strip of your item cards (highlight =
  trading-card preview, A = full card); BACK / B returns. Items are modelled at
  real-life size per platform (`ItemModels.REAL_*`, metres of the longest side). Perk cards are
  trading cards: category colour (`PERK_CATS`), striped art, effect badge.
- Scrolling: `_scroll_col` remembers its position across rebuilds, fades its
  edges when there's more, and a drag never counts as a tap (`_guarded`).
- NEW RUN opens the how-to-play guide first (`_open_guide`, pages in `GUIDE`):
  swipeable cards with big pictures and short funny lines; a toggle on the last
  page turns it off (`guide_off` in the save). HOW TO PLAY opens it too.
- COLLECTION (title screen) lasts across runs, saved in `user://collection.cfg`:
  THE WALL (up to 24 hung finds: "Hang on your Wall" from a shelf item, or one
  pick when a run ends) and the BINDER (every catalog item by platform: WALL /
  OWN NOW / OWNED / SEEN / ? not yet). Anything shown in a stop counts as seen.
- Xbox-style controller (`# controller` in game.gd): stick / D-pad move focus,
  A press, B back / close, Y = the screen's main action (buttons marked with
  `_mark_main`), X = switch halves (sale/shelf, route/shelf, wall/binder),
  LB / RB tabs (guide pages, binder consoles), LT / RT page-scroll, View = how
  to play; D-pad moves anywhere. Landscape screens: each stick drives its own side
  panel (`_side_stick`: first push hops the highlight there, then smooth scroll with
  the highlight following, stepping where it can't scroll). Phones / popups: LEFT stick
  moves the highlight (`_stick_nav`), RIGHT stick scrolls the list it's in. Axes are read from any pad (`_axis`); on the
  item card the left stick turns the model and the right stick scrolls the info.
  Godot's ui_* stick events are removed at startup so the sticks are ours.
  Text is bigger in landscape (`FONT_SCALE` 1.36, `_fsz` floor of 15),
  Start skips the intro or starts a run. Pad mode shows a cyan focus frame,
  subtle Xbox glyphs (`_glyph`: Y on main buttons, LB/RB on tab bars) and a
  hint strip at the bottom; touch or mouse turns it all off. Focus is restored
  by button identity after each rebuild and kept inside the top layer.
- Landscape shows compact tiles (`_offer_tile`, small `_shelf_tile`) so a whole
  table fits; highlighting a tile (pad focus, or mouse hover on desktop) pops a
  trading-card preview (`_show_preview`) that fills the
  middle gap (`_gap` rect); A / click opens the full card.
  Right stick turns the item card's model by hand (Y tilts); auto spin resumes
  after 3 s.
- Landscape = three columns (`_land_cols`): tall panels left and right, the 3D
  room in the middle strip (camera `look_down`), the main action button under it.
- Screen changes go through `_transition` (a quick dip to black) so rebuilds
  don't stutter on slow devices. With a title it's a loading screen (DRIVING TO
  ..., OPENING UP THE GARAGE, HEADING HOME): the room is built and every box
  cover painted (`Art.loading` = full speed, `Art.pending()` drives the bar)
  before the reveal; tips/jokes in `LOADING_TIPS`. `tools/pad_probe.gd` plays the start with simulated pad presses and prints
  the focus after each; `tools/pad_play.gd` plays whole runs with only pad presses and lists
  PROBLEMS (unreachable buttons, lost focus, dead presses); `tools/nav_dump.gd` prints
  where each D-pad direction goes from every button. D-pad steering is our own
  (`_pad_move`/`_nav_pick`: stays in the top layer, finishes a list before leaving it,
  hold to repeat, smooth scroll); focus returns to the opener when a sheet closes; `tools/perf_probe.gd` prints frame times and
  the CPU cost of room builds, UI rebuilds and cover painting.
- Tapping any item opens a full-screen trading card (`_open_inspect`): its 3D
  model spinning on a turntable (drag to turn), stat bars, set progress,
  flavor and the actions. Landscape = a wide 16:9 card (item left, info and
  actions right). `_open_sheet(..., item)` routes there.
- Opening sequence (`_start_intro` in game.gd, once per launch): a sound gate
  first (PLAY WITH SOUND / PLAY MUTED; browsers need a tap before audio), a
  SKIP button during the show, tap at the logo to continue. Then:
  studio card, Stage cinematic camera (`cine_on`/`cine_pos`) flying a spline
  through the title vault, grail box drop, logo slam over light rays, then the
  title UI fades in (box art paints behind the gate and studio card; no loading card
  here: LOADING THE VAULT is the transition into COLLECTION). Frames: `xvfb-run ... -s res://tools/intro_shots.gd -- OUT_DIR`.
- Music is ambient dream pop / synthwave throughout (title, home, hunt, shop,
  online, ending), normalised mono ogg with fades so loops are soft.
- The UI leaves a see-through gap under the header (`_stage_gap`) and aims the
  3D camera at it (`_update_focus`). Panels are smoked glass (alpha ~0.9).
- Catalog: ~770 items. `catalog.gd` HANDMADE items + `catalog_items.gd`, a
  GENERATED one-to-one parody of `docs/research/retro_gaming_top_500.txt` and
  `retro_hardware_top_250.txt` (`python3 tools/gen_catalog.py`; edit the
  generator, never the output). Parody names only, original art only (no real
  cover art). Each def has rank, year, publisher, genre, blurb, rating, print run.
- Variants (`Catalog.VARIANTS`): each copy rolls one (Player's Pick, Black Label,
  First Print, Misprint, Test Cart, Rental, Collector's, Signed, Launch,
  Prototype...), multiplying value. Hunt sellers price as if Standard.
  Each run deals in `Balance.ACTIVE_PLATFORMS` random platforms (+ wildcards).
- Item art is made at runtime by `scripts/gfx/art.gd` (`Art.front/back/icon`),
  painted by `box_art.gd` (platform box templates, variant overlays, back with
  screenshots/blurb/rating/barcode) with illustrations from `cover_comp.gd`:
  sprites (`assets/sprites/cover/`: Kenney plus pixel-art packs — gothic, cyberpunk,
  ninja, bosses, starships, painted backdrops, plus characters from open-source
  games on GitHub — Superpowers, Wesnoth, Tuxemon, SuperTux, Freedoom, Pixel
  Dungeon; manifest `cover_sprites.gd`, built by
  `python3 tools/gen_cover_sprites.py SRC SRC2 SRC3`; it wipes the folder, so
  `git checkout` the old `.import` files after to keep their uids), seeded palettes, ~16
  layouts per genre, genre title fonts (`assets/fonts/cover/`, OFL), a logo
  badge + stripe per publisher. Covers also show what the title is about: glossy CG
  renders (`assets/sprites/subject/`, Microsoft Fluent 3D emoji, MIT) picked from title
  words (`Subjects.WORDS`, then generic `WEAK`, then `GENRE`), drawn by `CoverComp._compose_cg`
  (or as a corner prop on pixel covers). Edit `tools/gen_subjects.py` (needs a sparse clone
  of github.com/microsoft/fluentui-emoji), never `scripts/gfx/subjects.gd`; it writes lossy
  imports. Hardware boxes show a render of the product. Check it with
  `xvfb-run ... -s res://tools/art_sheet.gd -- OUT.png [seed]`.
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

## Weak devices
- `scripts/gfx/lite.gd`: `?lite=1` on the page address turns off the 3D rooms,
  rendered art and CRT overlay (or one at a time: `?no3d=1`, `?noart=1`,
  `?nocrt=1`). The page's startup script shows errors on screen and reloads
  with `?lite=1` if the full build crashes (seen on an Android TV browser).
- Android TV app: CI also exports preset "Android TV" (arm32+arm64, debug-signed,
  feature tag `tv` = landscape) and publishes it as `tv.apk` next to the web
  game. Install on a TV with Downloader by AFTVnews. Never blocks the web deploy.
  The `tv` feature turns on `Lite.perf` (3D at ~360 px tall, no sun shadows,
  fewer art renders per frame, 30 fps cap, no CRT); `?perf=1` does it on web.
  TV remote arrows / OK / BACK drive the same focus as a pad. A presses the
  focused button directly (Android doesn't map it to ui_accept). The TV app
  draws at the base size (content_scale_mode VIEWPORT) and lets the TV scale up.
- TV self-update: main scene is `scenes/boot.tscn` (`scripts/boot/boot.gd`). On
  the `tv` build it checks `tv-version.txt` (CI build time, also in
  `res://build_id.txt`) and downloads `tv-game.pck` into user:// when newer, then
  loads it over the built-in data. If the new data never reaches the game's
  `_confirm_boot`, the next launch deletes it. Other platforms skip straight to
  `main.tscn`. New `class_name` scripts may need a fresh tv.apk install.
- GFX button on the title: FULL / FAST / LITE (`Lite.set_level`, saved as `gfx`).
- Perf mode "pre-renders" the room: the Stage viewport only redraws for a few
  frames after a change (`mark_dirty`), twice a second for new box art, and
  every frame during the intro flight. Apps also cache painted covers/renders in
  `user://art_cache/<build>/` so later launches skip painting them.
- The camera holds still (no idle sway) and vertex snap is fine (700) so
  polygons don't shimmer; only intended motion moves.
- Pause menu: the `II` button in the header (or Start / B on a pad): resume,
  how to play, sound, graphics, quit to title (run is kept; the title shows
  CONTINUE RUN), close the game (apps only; BACK on the title also closes).
- Debug HUD (TV app, or `?debug=1`): FPS, last input event, pads connected,
  pad mode, focused button and the version, bottom right.
- Version = `v0.1.<CI run number>` (`build_run.txt`, written by CI; the title
  screen shows it too). The intro paints the vault's box art behind the sound
  gate and the studio card (no loading card in the intro).
- CI also publishes `tv-basic.apk` (quick export, no internet = no self-update);
  the Gradle `tv.apk` didn't install on Samuel's TV at 165 MB, now compressed libs.

## Testing pipeline
- Use Godot 4.3 (as CI does). If the container's `godot` is newer, grab the
  4.3-stable binary; a newer one breaks GUT and adds `.uid` files (don't commit them).
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
