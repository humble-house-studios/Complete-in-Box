extends Control
## First scene. On the Android TV app it fetches the newest game data from the
## play site before starting, so the TV only needs the app installed once:
##   tv-version.txt  build time of the newest data (unix seconds)
##   tv-game.pck     the game itself (same as inside the app, just newer)
## The download is cached in user://; offline, the newest copy on hand runs.
## If an update fails to start, the next launch throws it away and runs the
## copy built into the app. Everywhere else this goes straight to the game.

const SITE := "https://humble-house-studios.github.io/Complete-in-Box/"
const PCK := "user://update.pck"
const VER := "user://update_version.txt"
const PENDING := "user://update_pending"
const MAIN := "res://scenes/main.tscn"

var _status: Label
var _http: HTTPRequest
var _remote := 0


func _ready() -> void:
	if not OS.has_feature("tv"):
		_start.call_deferred()
		return
	_build_ui()
	# The last update never got the game running: drop it.
	if FileAccess.file_exists(PENDING):
		_forget_update()
	_http = HTTPRequest.new()
	_http.timeout = 6.0
	add_child(_http)
	_say("Checking for updates...")
	_http.request_completed.connect(_on_version)
	if _http.request(SITE + "tv-version.txt?t=%d" % Time.get_unix_time_from_system()) != OK:
		_launch()


func _on_version(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_http.request_completed.disconnect(_on_version)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_say("Offline, starting the game...")
		_launch()
		return
	_remote = body.get_string_from_utf8().strip_edges().to_int()
	if _remote <= maxi(_builtin(), _cached()):
		_launch()
		return
	_say("Downloading the newest version...")
	_http.timeout = 300.0
	_http.download_file = PCK + ".part"
	_http.request_completed.connect(_on_pck)
	if _http.request(SITE + "tv-game.pck?t=%d" % _remote) != OK:
		_launch()


func _on_pck(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var d := DirAccess.open("user://")
		if d != null:
			d.remove("update.pck")
			d.rename("update.pck.part", "update.pck")
			var f := FileAccess.open(VER, FileAccess.WRITE)
			if f != null:
				f.store_string(str(_remote))
				f.close()
	else:
		_say("Download failed, starting the game...")
	_launch()


func _process(_d: float) -> void:
	if _http != null and _http.download_file != "" and _http.get_body_size() > 0:
		_say("Downloading the newest version... %d%%" % int(100.0 * _http.get_downloaded_bytes() / _http.get_body_size()))


func _launch() -> void:
	if _cached() > _builtin() and FileAccess.file_exists(PCK):
		var f := FileAccess.open(PENDING, FileAccess.WRITE)
		if f != null:
			f.store_string("1")
			f.close()
		if not ProjectSettings.load_resource_pack(PCK, true):
			_forget_update()
	_start.call_deferred()


func _start() -> void:
	get_tree().change_scene_to_file(MAIN)


## Called by the game once it is up: the update worked.
static func confirm() -> void:
	if FileAccess.file_exists(PENDING):
		DirAccess.remove_absolute(PENDING)


func _forget_update() -> void:
	for p in [PCK, VER, PENDING]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _builtin() -> int:
	var f := FileAccess.open("res://build_id.txt", FileAccess.READ)
	return f.get_as_text().strip_edges().to_int() if f != null else 0


func _cached() -> int:
	if not FileAccess.file_exists(PCK):
		return 0
	var f := FileAccess.open(VER, FileAccess.READ)
	return f.get_as_text().strip_edges().to_int() if f != null else 0


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(v)
	var t := Label.new()
	t.text = "COMPLETE IN BOX"
	t.add_theme_font_override("font", load("res://assets/fonts/Jersey10-Regular.ttf"))
	t.add_theme_font_size_override("font_size", 72)
	t.add_theme_color_override("font_color", Color("ffcc33"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 28)
	_status.add_theme_color_override("font_color", Color("f2ead8"))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_status)


func _say(s: String) -> void:
	if _status != null:
		_status.text = s
