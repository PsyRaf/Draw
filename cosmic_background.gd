extends Control

const CYAN := Color("#00E5FF")
const MAGENTA := Color("#FF35D3")
const DARK := Color("#050817")
const EMPTY_LIFE := Color("#30384A")

var stars: Array[Vector3] = []
var lives: Array[int] = [0, 0]
var reactions: Array[int] = [-1, -1]

var phase: String = "MENU"
var elapsed: float = 0.0
var flash: float = 0.0
var shake: float = 0.0

var winner_index: int = -1
var loser_index: int = -1
var celebration_time: float = 0.0
var explosion_time: Array[float] = [0.0, 0.0]

var shockwave_radius: float = 0.0
var shockwave_alpha: float = 0.0

var burst_particles: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var rng := RandomNumberGenerator.new()
	rng.seed = 43

	for i in range(130):
		stars.append(Vector3(
			rng.randf(),
			rng.randf(),
			rng.randf_range(0.5, 2.2)
		))

	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	flash = maxf(0.0, flash - delta * 2.5)
	shake = maxf(0.0, shake - delta * 24.0)

	for i in range(stars.size()):
		var star: Vector3 = stars[i]
		star.y += delta * 0.012 * star.z
		if star.y > 1.0:
			star.y = 0.0
		stars[i] = star

	for i in range(2):
		explosion_time[i] = maxf(0.0, explosion_time[i] - delta)

	celebration_time = maxf(0.0, celebration_time - delta)

	if shockwave_alpha > 0.0:
		shockwave_radius += delta * 650.0
		shockwave_alpha = maxf(0.0, shockwave_alpha - delta * 1.5)

	for i in range(burst_particles.size() - 1, -1, -1):
		var p: Dictionary = burst_particles[i]
		p["pos"] = p["pos"] + p["vel"] * delta
		p["life"] = float(p["life"]) - delta
		burst_particles[i] = p

		if float(p["life"]) <= 0.0:
			burst_particles.remove_at(i)

	queue_redraw()


func set_scores(player1_wins: int, player2_wins: int) -> void:
	lives[0] = player1_wins
	lives[1] = player2_wins
	queue_redraw()


func set_reactions(player1_ms: int, player2_ms: int) -> void:
	reactions[0] = player1_ms
	reactions[1] = player2_ms
	queue_redraw()


func set_phase(new_phase: String) -> void:
	phase = new_phase

	if new_phase == "MENU" or new_phase == "READY":
		winner_index = -1
		loser_index = -1
		celebration_time = 0.0
		explosion_time = [0.0, 0.0]
		burst_particles.clear()

	elif new_phase == "SHOOT":
		flash = 1.0
		shake = 8.0
		shockwave_radius = 0.0
		shockwave_alpha = 1.0
		spawn_burst(size / 2.0, Color.WHITE, 45)

	queue_redraw()


func finish_round_effects(winner: int, duration: float = 3.0) -> void:
	if winner < 0:
		flash = 0.35
		shake = 4.0
		queue_redraw()
		return

	winner_index = winner
	loser_index = 1 - winner
	celebration_time = duration

	var center_y: float = 0.73 if loser_index == 0 else 0.27
	var loser_center := Vector2(size.x / 2.0, size.y * center_y)
	var loser_color: Color = CYAN if loser_index == 0 else MAGENTA

	# Keeps the portal destroyed for the exact 3-second round break duration
	explosion_time[loser_index] = duration
	spawn_burst(loser_center, loser_color, 65)

	shake = 12.0
	flash = 0.8
	queue_redraw()


func spawn_burst(center: Vector2, tint: Color, amount: int = 30) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(amount):
		var angle: float = rng.randf_range(0.0, TAU)
		var speed: float = rng.randf_range(70.0, 260.0)

		burst_particles.append({
			"pos": center,
			"vel": Vector2.RIGHT.rotated(angle) * speed,
			"life": rng.randf_range(0.35, 0.9),
			"max_life": 0.9,
			"size": rng.randf_range(2.0, 5.0),
			"color": tint
		})

	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var radius: float = minf(w, h) * 0.105

	var offset := Vector2.ZERO
	if shake > 0.0:
		offset = Vector2(
			sin(elapsed * 70.0) * shake,
			cos(elapsed * 83.0) * shake
		)

	draw_rect(Rect2(Vector2.ZERO, size), DARK, true)

	for star in stars:
		var pos := Vector2(star.x * w, star.y * h) + offset
		var twinkle: float = 0.55 + 0.45 * sin(elapsed * 3.0 + star.x * 30.0)
		draw_circle(pos, star.z, Color(0.65, 0.8, 1.0, twinkle))

	if phase != "MENU":
		var top_center := Vector2(w / 2.0, h * 0.27) + offset
		var bottom_center := Vector2(w / 2.0, h * 0.73) + offset

		# Top portal = Player 2 (Index 1)
		if explosion_time[1] <= 0.0:
			var top_power: float = 1.0
			if winner_index == 1 and celebration_time > 0.0:
				top_power = 1.0 + 0.35 * absf(sin(elapsed * 18.0))
			draw_portal(top_center, MAGENTA, radius, top_power)

		# Bottom portal = Player 1 (Index 0)
		if explosion_time[0] <= 0.0:
			var bottom_power: float = 1.0
			if winner_index == 0 and celebration_time > 0.0:
				bottom_power = 1.0 + 0.35 * absf(sin(elapsed * 18.0))
			draw_portal(bottom_center, CYAN, radius, bottom_power)

		# Top UI = PLAYER 2 (Index 1)
		draw_player_ui(
			Vector2(w / 2.0, h * 0.10) + offset,
			"PLAYER 2", MAGENTA, lives[1], reactions[1], true
		)

		# Bottom UI = PLAYER 1 (Index 0)
		draw_player_ui(
			Vector2(w / 2.0, h * 0.88) + offset,
			"PLAYER 1", CYAN, lives[0], reactions[0], false
		)

	if shockwave_alpha > 0.0:
		var wave_color := Color(0.7, 0.95, 1.0, shockwave_alpha)
		draw_arc(
			Vector2(w / 2.0, h / 2.0),
			shockwave_radius,
			0.0,
			TAU,
			96,
			wave_color,
			4.0,
			true
		)

	for p in burst_particles:
		var alpha: float = clampf(
			float(p["life"]) / float(p["max_life"]), 0.0, 1.0
		)
		var tint: Color = p["color"]
		tint.a = alpha
		draw_circle(p["pos"], float(p["size"]) * alpha, tint)

	if flash > 0.0:
		draw_rect(
			Rect2(Vector2.ZERO, size),
			Color(0.4, 0.9, 1.0, flash * 0.10),
			true
		)


func draw_portal(center: Vector2, tint: Color, radius: float, power: float) -> void:
	var pulse: float = power * (1.0 + 0.045 * sin(elapsed * 3.5))
	var r: float = radius * pulse

	draw_circle(center, r * 1.55, Color(tint, 0.025 * power))
	draw_circle(center, r * 1.30, Color(tint, 0.055 * power))
	draw_circle(center, r * 1.12, Color(tint, 0.08 * power))

	draw_arc(
		center, r, elapsed * 0.25, elapsed * 0.25 + TAU,
		96, Color(tint, 0.95), 3.0, true
	)
	draw_arc(
		center, r * 0.82, -elapsed * 0.45, -elapsed * 0.45 + TAU,
		96, Color(tint, 0.65), 2.0, true
	)
	draw_arc(
		center, r * 0.62, elapsed * 0.7, elapsed * 0.7 + TAU,
		96, Color(tint, 0.4), 1.5, true
	)

	draw_circle(center, r * 0.22, Color(tint, 0.12 + flash * 0.15))
	draw_circle(center, r * 0.12, Color(tint, 0.25))
	draw_circle(center, r * 0.045, Color.WHITE)


func draw_player_ui(
	center: Vector2,
	player_name: String,
	tint: Color,
	wins: int,
	reaction_ms: int,
	upside_down: bool
) -> void:
	var reaction_text := "LAST: -- ms"
	if reaction_ms >= 0:
		reaction_text = "LAST: " + str(reaction_ms) + " ms"

	if upside_down:
		draw_set_transform(center, PI, Vector2.ONE)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(-100, -16),
			player_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			200,
			18,
			tint
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(-100, 5),
			reaction_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			200,
			14,
			Color(0.72, 0.88, 0.96)
		)

		for i in range(5):
			var life_color: Color = tint if i < wins else EMPTY_LIFE
			var life_radius: float = 6.0 if i < wins else 5.0
			draw_circle(Vector2(-40 + i * 20, 23), life_radius, life_color)

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(-100, 0),
			player_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			200,
			18,
			tint
		)

		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(-100, 22),
			reaction_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			200,
			14,
			Color(0.72, 0.88, 0.96)
		)

		for i in range(5):
			var life_color: Color = tint if i < wins else EMPTY_LIFE
			var life_radius: float = 6.0 if i < wins else 5.0
			draw_circle(
				center + Vector2(-40 + i * 20, 43),
				life_radius,
				life_color
			)
