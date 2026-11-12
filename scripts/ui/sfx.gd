class_name Sfx
extends Node
## Tiny synthesized sound effects (no audio files): coin, tick, buzz, jingle.
## Built once as AudioStreamWAV; played on a small pool of players.

const RATE := 22050

var _streams: Dictionary = {}
var _players: Array = []
var _next: int = 0
var enabled: bool = true


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_players.append(p)
	_streams["coin"] = _tones([[988.0, 0.06], [1319.0, 0.14]], 0.35)
	_streams["tick"] = _tones([[1600.0, 0.025]], 0.25)
	_streams["buzz"] = _tones([[140.0, 0.18]], 0.3, true)
	_streams["haggle"] = _tones([[660.0, 0.05], [880.0, 0.05], [1100.0, 0.08]], 0.3)
	_streams["pass"] = _tones([[523.0, 0.09], [659.0, 0.09], [784.0, 0.09], [1047.0, 0.22]], 0.35)
	_streams["fail"] = _tones([[392.0, 0.15], [330.0, 0.15], [262.0, 0.3]], 0.35, true)
	_streams["spin"] = _tones([[700.0, 0.02]], 0.2)
	_streams["land"] = _tones([[440.0, 0.04], [880.0, 0.1]], 0.3)
	_streams["grail"] = _tones([[784.0, 0.08], [988.0, 0.08], [1175.0, 0.08], [1568.0, 0.3]], 0.35)


func play(id: String, pitch: float = 1.0) -> void:
	if not enabled or not _streams.has(id) or _players.is_empty():
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[id]
	p.pitch_scale = pitch
	p.play()


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
