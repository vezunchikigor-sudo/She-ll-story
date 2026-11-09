extends Node

var critical := false
var music_player: AudioStreamPlayer
var current_music := ""
var streams: Dictionary = {}

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.name = "Music"
    music_player.volume_db = -7.0
    add_child(music_player)
    for n in ["menu_music","mansion_ambience","ui_click","pistol","shotgun","uzi","rocket","knife","reload","footstep"]:
        streams[n] = _load_ogg("res://audio/" + n + ".ogg")

func _load_ogg(path: String) -> AudioStream:
    # Load OGG directly at runtime. This avoids parse-time preload/import failures.
    var s := AudioStreamOggVorbis.load_from_file(path)
    if s != null:
        s.loop = path.contains("menu_music") or path.contains("mansion_ambience")
    return s

func play_music(kind: String) -> void:
    var key := "menu_music" if kind == "menu" else "mansion_ambience"
    if current_music == kind and music_player.playing:
        return
    current_music = kind
    var s: AudioStream = streams.get(key)
    music_player.stop()
    if s != null:
        music_player.stream = s
        music_player.play()
    else:
        _start_fallback_music(kind)

func _start_fallback_music(kind: String) -> void:
    # Musical fallback, not a single flat hum.
    var gen: AudioStreamGenerator = AudioStreamGenerator.new()
    gen.mix_rate = 22050
    gen.buffer_length = 3.0
    music_player.stream = gen
    music_player.play()
    _fill_music(music_player.get_stream_playback() as AudioStreamGeneratorPlayback, kind)

func _fill_music(pb: AudioStreamGeneratorPlayback, kind: String) -> void:
    if pb == null:
        return
    var rate: int = 22050
    var count: int = rate * 3
    var notes: Array[float] = [110.0, 130.81, 146.83, 164.81, 146.83, 130.81, 98.0, 110.0]
    var frames: PackedVector2Array = PackedVector2Array()
    for i in count:
        var t := float(i) / rate
        var step := int(t / 0.375) % notes.size()
        var f: float = float(notes[step])
        var attack: float = min(1.0, t / 0.04)
        var release: float = min(1.0, (3.0 - t) / 0.35)
        var env: float = attack * release
        var v: float = (sin(t * f * TAU) * 0.028 + sin(t * f * 2.0 * TAU) * 0.012) * env
        if kind != "menu":
            v *= 0.55
        frames.append(Vector2(v, v))
    pb.push_buffer(frames)

func stop_music() -> void:
    current_music = ""
    music_player.stop()

func _play_named(name: String, volume_db: float = 0.0) -> void:
    var s: AudioStream = streams.get(name)
    if s != null:
        var p := AudioStreamPlayer.new()
        p.stream = s
        p.volume_db = volume_db
        add_child(p)
        p.finished.connect(p.queue_free)
        p.play()
        return
    _play_procedural(name, volume_db)

func _play_procedural(name: String, volume_db: float) -> void:
    var gen: AudioStreamGenerator = AudioStreamGenerator.new()
    gen.mix_rate = 22050
    gen.buffer_length = 0.22
    var p := AudioStreamPlayer.new()
    p.stream = gen
    p.volume_db = volume_db
    add_child(p)
    p.finished.connect(p.queue_free)
    p.play()
    var pb: AudioStreamGeneratorPlayback = p.get_stream_playback() as AudioStreamGeneratorPlayback
    if pb == null:
        return
    var rate: int = 22050
    var duration: float = 0.18 if name == "footstep" else 0.28
    var count: int = int(rate * duration)
    var frames := PackedVector2Array()
    for i in count:
        var t: float = float(i) / rate
        var v: float = 0.0
        if name == "footstep":
            var env: float = exp(-t * 34.0)
            v = (sin(t * 73.0 * TAU) * 0.14 + sin(t * 151.0 * TAU) * 0.06 + sin(t * 290.0 * TAU) * 0.018) * env
            if t < 0.012:
                v += sin(t * 820.0 * TAU) * 0.035 * (1.0 - t / 0.012)
        elif name == "enemy_pain":
            var f: float = 125.0 + 32.0 * sin(t * 5.0 * TAU)
            v = (sin(t * f * TAU) * 0.20 + sin(t * f * 2.01 * TAU) * 0.08) * exp(-t * 8.0)
        elif name == "player_pain":
            var f2: float = 180.0 + 28.0 * sin(t * 4.0 * TAU)
            v = (sin(t * f2 * TAU) * 0.18 + sin(t * f2 * 1.97 * TAU) * 0.06) * exp(-t * 8.0)
        else:
            var freq: float = 520.0 if name == "ui_click" else (260.0 if name == "reload" else 720.0)
            v = sin(t * freq * TAU) * exp(-t * 15.0) * 0.20
        frames.append(Vector2(v, v))
    pb.push_buffer(frames)

func set_critical_health(v: bool) -> void:
    critical = v

func play_player_pain(_kind: int = 1) -> void:
    _play_named("player_pain", -2.0)

func play_enemy_pain() -> void:
    _play_named("enemy_pain", -1.0)

func play_weapon(name: String) -> void:
    var k: String = str({"Pistol":"pistol","Shotgun":"shotgun","Uzi":"uzi","RocketLauncher":"rocket","Knife":"knife"}.get(name, "pistol"))
    _play_named(k, -1.5)

func play_reload() -> void:
    _play_named("reload", -3.0)

func play_footstep() -> void:
    _play_named("footstep", -4.0)

func ui_click() -> void:
    _play_named("ui_click", -3.0)
