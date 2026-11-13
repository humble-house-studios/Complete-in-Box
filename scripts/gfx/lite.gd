class_name Lite
extends RefCounted
## Fallbacks for weak devices (TV browsers, old phones) that crash on the full
## look. Set from the web page address: ?lite=1 turns everything off,
## or pick: ?no3d=1 (3D rooms + turntable), ?noart=1 (rendered box art and
## item renders), ?nocrt=1 (screen overlay shader). The page switches to
## ?lite=1 by itself if the game crashes on start.

static var no3d := false
static var noart := false
static var nocrt := false
## Performance mode (TV app, or ?perf=1): lower 3D resolution, no sun
## shadows, fewer art renders per frame, 30 fps cap, no CRT overlay.
static var perf := false
## Shows an FPS / last-input readout (TV app, or ?debug=1).
static var debug := false
## Dev buttons at Home (+$100, +1 ante): ?dev=1 on the web, always off in apps.
static var dev := false
static var _ready := false


static func init() -> void:
	if _ready:
		return
	_ready = true
	if OS.has_feature("tv"):
		perf = true
		nocrt = true
		debug = true
	if not OS.has_feature("web"):
		return
	var q := str(JavaScriptBridge.eval("window.location.search", true))
	var lite := q.contains("lite=1")
	no3d = lite or q.contains("no3d=1")
	noart = lite or q.contains("noart=1")
	nocrt = lite or q.contains("nocrt=1")
	perf = perf or lite or q.contains("perf=1")
	debug = q.contains("debug=1")
	dev = q.contains("dev=1")


## Graphics setting from the title screen: 0 full, 1 fast, 2 lite.
static func set_level(level: int) -> void:
	perf = level >= 1
	nocrt = level >= 1
	no3d = level >= 2
	noart = level >= 2


static func level() -> int:
	return 2 if no3d else (1 if perf else 0)


static func any() -> bool:
	return no3d or noart or nocrt or perf
