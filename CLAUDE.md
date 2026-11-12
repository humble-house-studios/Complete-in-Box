# Complete-in-Box

Godot 4.7 project (`project.godot` at repo root).

## Assets

- Grab any asset I ask for from anywhere, using `tools/grab.sh <url> <dest_folder>`
  (e.g. `tools/grab.sh https://opengameart.org/content/ui-pack assets/ui/kenney_ui`).
  It accepts direct files/archives or OpenGameArt-style pages, keeps only usable files,
  converts audio to .ogg and 3D to .glb.
- Always log the source URL (grab.sh appends `path | url | date` to `assets/sources.txt`;
  add a line by hand if you add something another way). Don't worry about licenses.
- After adding assets, run a headless import and fix or report any errors:
  `godot --headless --path . --import`
- Folders: `assets/{audio/sfx,audio/music,sprites,ui,models,textures,fonts}`.
  `.glb`/audio files go through Git LFS (see `.gitattributes`). Commit the `*.import` files.
- Tool deps: `apt-get install -y assimp-utils p7zip-full ffmpeg unzip`; Godot from
  `https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=linux.x86_64.zip&platform=linux.64`.
- Blocked from cloud sessions: kenney.nl (403), poly.pizza (Cloudflare). OpenGameArt works
  and mirrors most Kenney packs.
