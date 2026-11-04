
extends Node

const SAMPLE_RATE := 22050

var player: AudioStreamPlayer
var sounds: Dictionary = {}
var hum_playing := false


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "ProceduralAudioPlayer"
	add_child(player)

	sounds["hum"] = generate_sound("hum", 2.0, true)
	sounds["tension"] = generate_sound("tension", 1.4)
	sounds["laser"] = generate_sound("laser", 0.28)
	sounds["explosion"] = generate_sound("explosion", 0.9)


func generate_sound(kind: String, duration: float, looping := false) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)

	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var progress := t / duration
		var value := 0.0

		match kind:
			"hum":
				var frequency := 48.0 + 3.0 * sin(t * TAU * 0.4)
				phase += TAU * frequency / SAMPLE_RATE
				value = sin(phase) * 0.17
				value += sin(phase * 2.01) * 0.055
				value += sin(phase * 3.0) * 0.025

			"tension":
				var frequency := lerpf(110.0, 850.0, progress * progress)
				phase += TAU * frequency / SAMPLE_RATE
				var envelope := sin(progress * PI * 0.5)
				value = (sin(phase) * 0.20 + sin(phase * 1.5) * 0.07) * envelope
				value += rng.randf_range(-0.025, 0.025) * envelope

			"laser":
				var frequency := lerpf(1300.0, 180.0, progress)
				phase += TAU * frequency / SAMPLE_RATE
				var envelope := exp(-progress * 7.0)
				value = sin(phase) * 0.55 * envelope
				value += sin(phase * 0.5) * 0.12 * envelope

			"explosion":
				var envelope := exp(-progress * 5.5)
				var low_frequency := lerpf(95.0, 35.0, progress)
				phase += TAU * low_frequency / SAMPLE_RATE
				var noise := rng.randf_range(-1.0, 1.0)
				value = (sin(phase) * 0.55 + noise * 0.35) * envelope

		# Gentle fade at the beginning and end to avoid clicks.
		var fade_in := minf(1.0, t / 0.015)
		var fade_out := 1.0
		if not looping:
			fade_out = minf(1.0, (duration - t) / 0.04)

		value *= fade_in * fade_out
		value = clampf(value, -0.95, 0.95)

		var pcm := int(value * 32767.0)
		bytes.encode_s16(i * 2, pcm)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes

	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count

	return stream


func play_sound(kind: String) -> void:
	if not sounds.has(kind):
		return

	player.stop()
	player.stream = sounds[kind]
	player.play()


func start_hum() -> void:
	if hum_playing:
		return

	hum_playing = true
	player.stop()
	player.stream = sounds["hum"]
	player.play()


func stop_hum() -> void:
	hum_playing = false
	if player.stream == sounds.get("hum"):
		player.stop()


func play_tension() -> void:
	play_sound("tension")


func play_laser() -> void:
	hum_playing = false
	play_sound("laser")


func play_explosion() -> void:
	hum_playing = false
	play_sound("explosion")
