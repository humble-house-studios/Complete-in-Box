class_name Sfx
extends Node
## Sound effects, music and room ambience.
## Effects are real recordings in assets/audio/sfx (several takes per sound,
## picked at random so repeats don't sound robotic). If a file is missing the
## old synthesized tone plays instead. Music crossfades between tracks in
## assets/audio/music; each venue type has its own track and some add ambience.

const RATE := 22050
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

## id -> [files (random take), volume dB]
const SOUNDS := {
	"coin": [["coins1", "coins2", "coins3"], -4.0],
	"buy": [["chips_stack", "chips_handle"], -3.0],
	"tick": [["chip1", "chip2", "chip3"], -2.0],
	"mult": [["chips_collide"], -1.0],
	"buzz": [["error"], -6.0],
	"haggle": [["haggle"], -4.0],
	"pass": [["pass"], -2.0],
	"fail": [["fail"], -2.0],
	"spin": [["tick"], -8.0],
	"land": [["place1", "place2"], -2.0],
	"grail": [["grail"], -1.0],
	"click": [["click"], -10.0],
	"open": [["slide_in"], -6.0],
	"close": [["slide_out"], -8.0],
	"dig": [["rummage", "paper"], -3.0],
	"lot": [["pack_open"], -2.0],
	"stamp": [["stamp"], -1.0],
	"thud": [["thud"], -2.0],
	"bargain": [["bargain"], -4.0],
	"win": [["win"], -1.0],
	"shake": [["shake"], -4.0],
	"door": [["drop", "metal"], -6.0],
}

## Music per screen/venue slot, plus optional ambience bed per venue.
const TRACKS := {"title": "title", "home": "home", "hunt": "hunt", "shop": "shop", "online": "online", "ending": "ending"}
const AMBIENCE := {"flea": "amb_crowd", "convention": "amb_crowd", "storage": "amb_rain"}

var _streams: Dictionary = {}
var _players: Array = []
var _next: int = 0
var _music: Array = []
var _music_on := 0
var _track := ""
var _amb: AudioStreamPlayer
var _amb_id := ""
var _duck := 0.0
var _tweens: Dictionary = {}
var enabled: bool = true
var music_enabled: bool = true


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = &"Effects"
		add_child(p)
		_players.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = &"Music"
		m.volume_db = -80.0
		add_child(m)
		_music.append(m)
	_amb = AudioStreamPlayer.new()
	_amb.bus = &"Music"
	_amb.volume_db = -80.0
	add_child(_amb)
	for id in SOUNDS:
		var takes: Array = []
		for f in SOUNDS[id][0]:
			var path: String = SFX_DIR + String(f) + ".ogg"
			if ResourceLoader.exists(path):
				takes.append(load(path))
		if not takes.is_empty():
			_streams[id] = takes
	# Synth fallbacks for anything without a file.
	var synth := {
		"coin": _tones([[988.0, 0.06], [1319.0, 0.14]], 0.35),
		"tick": _tones([[1600.0, 0.025]], 0.25),
		"buzz": _tones([[140.0, 0.18]], 0.3, true),
		"haggle": _tones([[660.0, 0.05], [880.0, 0.05], [1100.0, 0.08]], 0.3),
		"pass": _tones([[523.0, 0.09], [659.0, 0.09], [784.0, 0.09], [1047.0, 0.22]], 0.35),
		"fail": _tones([[392.0, 0.15], [330.0, 0.15], [262.0, 0.3]], 0.35, true),
		"spin": _tones([[700.0, 0.02]], 0.2),
		"land": _tones([[440.0, 0.04], [880.0, 0.1]], 0.3),
		"grail": _tones([[784.0, 0.08], [988.0, 0.08], [1175.0, 0.08], [1568.0, 0.3]], 0.35),
	}
	for id in synth:
		if not _streams.has(id):
			_streams[id] = [synth[id]]


func play(id: String, pitch: float = 1.0) -> void:
	if not enabled or not _streams.has(id) or _players.is_empty():
		return
	var takes: Array = _streams[id]
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = takes[randi() % takes.size()]
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.volume_db = float(SOUNDS[id][1]) if SOUNDS.has(id) else -8.0
	p.play()


## Crossfades to a track (title/home/hunt/shop/online) and sets the ambience
## bed for a venue id ("" = none).
func music(track: String, venue: String = "") -> void:
	var amb: String = AMBIENCE.get(venue, "")
	if amb != _amb_id:
		_amb_id = amb
		_fade(_amb, -80.0, 0.6)
		if amb != "":
			var s := _load_loop(amb)
			if s != null:
				_amb.stream = s
				_amb.play()
				_fade(_amb, -20.0 + _duck, 1.0)
	if track == _track:
		return
	_track = track
	var file: String = TRACKS.get(track, "")
	var old: AudioStreamPlayer = _music[_music_on]
	_fade(old, -80.0, 1.2, true)
	if file == "" or not music_enabled:
		return
	var s2 := _load_loop(file)
	if s2 == null:
		return
	_music_on = 1 - _music_on
	var p: AudioStreamPlayer = _music[_music_on]
	p.stream = s2
	p.volume_db = -40.0
	p.play()
	_fade(p, _music_db(), 1.5)


## Pulls the music down (appraisal tension) or back up.
func duck(on: bool) -> void:
	_duck = -10.0 if on else 0.0
	_fade(_music[_music_on], _music_db(), 0.4)
	if _amb.playing:
		_fade(_amb, -20.0 + _duck, 0.4)


func set_music_enabled(on: bool) -> void:
	music_enabled = on
	if not on:
		for m in _music:
			_fade(m, -80.0, 0.3, true)
		_fade(_amb, -80.0, 0.3, true)
		_track = ""
		_amb_id = ""


func _music_db() -> float:
	return -9.0 + _duck


func _load_loop(file: String) -> AudioStream:
	var path := MUSIC_DIR + file + ".ogg"
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path)
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	return s


func _fade(p: AudioStreamPlayer, db: float, t: float, stop_after: bool = false) -> void:
	if p == null or not is_inside_tree():
		return
	if _tweens.has(p) and (_tweens[p] as Tween).is_valid():
		(_tweens[p] as Tween).kill()
	var tw := create_tween()
	_tweens[p] = tw
	tw.tween_property(p, "volume_db", db, t)
	if stop_after:
		tw.tween_callback(p.stop)


func _tones(notes: Array, vol: float, square: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	for n in notes:
		var freq: float = n[0]
		var dur: float = n[1]
		var count := int(dur * RATE)
		for i in count:
			var t := float(i) / RATE
			var env := minf(1.0, float(i) / 200.0) * (1.0 - float(i) / count)
			var s: float
			if square:
				s = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
				s *= 0.5
			else:
				s = sin(TAU * freq * t)
			var v := int(clampf(s * env * vol, -1.0, 1.0) * 32767.0)
			data.append(v & 0xFF)
			data.append((v >> 8) & 0xFF)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
