extends Control

enum GameState {
	MENU,
	READY,
	WAITING,
	SHOOT,
	ROUND_OVER,
	MATCH_OVER
}

enum GameMode {
	PVP,
	AI_EASY,
	AI_MEDIUM,
	AI_HARD
}

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_stream_player_2d_2: AudioStreamPlayer2D = $AudioStreamPlayer2D2
var bgm_player: AudioStreamPlayer

const TARGET_WINS := 5

var state: GameState = GameState.MENU
var game_mode: GameMode = GameMode.PVP
var scores: Array[int] = [0, 0] # Index 0 = Player 1 (Bottom), Index 1 = Player 2 / AI (Top)
var reactions: Array[int] = [-1, -1]
var last_reactions: Array[int] = [-1, -1]

var shoot_time: int = 0
var round_id: int = 0
var ai_timer: SceneTreeTimer = null

var status_label: Label
var menu_panel: PanelContainer
var menu_title: Label
var menu_subtitle: Label

var main_menu_vbox: VBoxContainer
var ai_menu_vbox: VBoxContainer

var play_button: Button
var ai_button: Button
var menu_button: Button
var quit_button: Button

var easy_button: Button
var medium_button: Button
var hard_button: Button
var back_ai_button: Button

var credit_label: Label
var sound_manager: Node

# Pause UI elements
var pause_button: Button
var pause_panel: PanelContainer
var resume_button: Button
var restart_button: Button
var pause_menu_button: Button
var pause_quit_button: Button
var is_paused: bool = false


func _ready() -> void:
	randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS

	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.stream = load("res://bg.wav")
	if bgm_player.stream is AudioStreamWAV:
		(bgm_player.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	add_child(bgm_player)
	bgm_player.play()
	
	var background = get_node_or_null("CosmicBackground")
	if background:
		background.z_index = -10
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.process_mode = Node.PROCESS_MODE_ALWAYS

	sound_manager = preload("res://SoundManager.gd").new()
	sound_manager.name = "SoundManager"
	add_child(sound_manager)

	status_label = Label.new()
	status_label.text = "DRAW!"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.anchor_left = 0.08
	status_label.anchor_right = 0.92
	status_label.anchor_top = 0.44
	status_label.anchor_bottom = 0.56
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_label)

	create_menu()
	create_pause_menu()
	update_background()
	set_background_phase("MENU")
	status_label.hide()
	pause_button.hide()
	pause_panel.hide()


func create_menu() -> void:
	menu_panel = PanelContainer.new()
	menu_panel.name = "MainMenu"
	menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_panel.custom_minimum_size = Vector2(340, 420)
	menu_panel.anchor_left = 0.5
	menu_panel.anchor_top = 0.5
	menu_panel.anchor_right = 0.5
	menu_panel.anchor_bottom = 0.5
	menu_panel.offset_left = -170
	menu_panel.offset_top = -210
	menu_panel.offset_right = 170
	menu_panel.offset_bottom = 210
	menu_panel.z_index = 10

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.06, 0.14, 0.95)
	panel_style.border_color = Color(0.0, 0.9, 1.0, 0.7)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_color = Color(0.0, 0.9, 1.0, 0.3)
	panel_style.shadow_size = 16
	menu_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	menu_panel.add_child(margin)

	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 14)
	margin.add_child(root_column)

	menu_title = Label.new()
	menu_title.text = "DRAW!"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_size_override("font_size", 20)
	menu_title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 1.0))
	root_column.add_child(menu_title)

	menu_subtitle = Label.new()
	menu_subtitle.text = "— COSMIC REACTION DUEL —"
	menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_subtitle.add_theme_font_size_override("font_size", 11)
	menu_subtitle.add_theme_color_override("font_color", Color(1.0, 0.2, 0.8, 0.9))
	root_column.add_child(menu_subtitle)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 6)
	root_column.add_child(sep)

	# --- MAIN MENU CONTAINER ---
	main_menu_vbox = VBoxContainer.new()
	main_menu_vbox.add_theme_constant_override("separation", 12)
	root_column.add_child(main_menu_vbox)

	play_button = create_scifi_button("2P DUEL", Color(0.0, 0.9, 1.0))
	play_button.pressed.connect(func(): start_match(GameMode.PVP))
	main_menu_vbox.add_child(play_button)

	ai_button = create_scifi_button("PRACTICE VS AI", Color(0.3, 1.0, 0.6))
	ai_button.pressed.connect(show_ai_menu)
	main_menu_vbox.add_child(ai_button)

	menu_button = create_scifi_button("MAIN MENU", Color(0.7, 0.8, 1.0))
	menu_button.pressed.connect(show_main_menu)
	main_menu_vbox.add_child(menu_button)

	quit_button = create_scifi_button("ABORT MISSION", Color(1.0, 0.3, 0.4))
	quit_button.pressed.connect(quit_game)
	main_menu_vbox.add_child(quit_button)

	menu_button.hide()

	# --- AI DIFFICULTY CONTAINER ---
	ai_menu_vbox = VBoxContainer.new()
	ai_menu_vbox.add_theme_constant_override("separation", 12)
	root_column.add_child(ai_menu_vbox)

	easy_button = create_scifi_button("AI: EASY", Color(0.3, 0.9, 1.0))
	easy_button.pressed.connect(func(): start_match(GameMode.AI_EASY))
	ai_menu_vbox.add_child(easy_button)

	medium_button = create_scifi_button("AI: MEDIUM", Color(1.0, 0.8, 0.2))
	medium_button.pressed.connect(func(): start_match(GameMode.AI_MEDIUM))
	ai_menu_vbox.add_child(medium_button)

	hard_button = create_scifi_button("AI: HARD", Color(1.0, 0.3, 0.4))
	hard_button.pressed.connect(func(): start_match(GameMode.AI_HARD))
	ai_menu_vbox.add_child(hard_button)

	back_ai_button = create_scifi_button("BACK", Color(0.7, 0.7, 0.9))
	back_ai_button.pressed.connect(show_main_menu_buttons)
	ai_menu_vbox.add_child(back_ai_button)

	ai_menu_vbox.hide()

	credit_label = Label.new()
	credit_label.name = "CreditLabel"
	credit_label.text = "Made from scratch by Rafsan Samin"
	credit_label.anchor_left = 1.0
	credit_label.anchor_top = 1.0
	credit_label.anchor_right = 1.0
	credit_label.anchor_bottom = 1.0
	credit_label.offset_left = -330
	credit_label.offset_top = -45
	credit_label.offset_right = -15
	credit_label.offset_bottom = -10
	credit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credit_label.add_theme_font_size_override("font_size", 14)
	credit_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 0.85))
	credit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credit_label.z_index = 10
	add_child(credit_label)

	# --- IN-GAME PAUSE BUTTON ---
	pause_button = create_scifi_button("II", Color(0.0, 0.9, 1.0))
	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.custom_minimum_size = Vector2(56, 56)
	pause_button.anchor_left = 1.0
	pause_button.anchor_top = 0.5
	pause_button.anchor_right = 1.0
	pause_button.anchor_bottom = 0.5
	pause_button.offset_left = -72
	pause_button.offset_top = -28
	pause_button.offset_right = -16
	pause_button.offset_bottom = 28
	pause_button.z_index = 15
	pause_button.pressed.connect(toggle_pause)
	add_child(pause_button)


func create_pause_menu() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.name = "PauseMenu"
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.custom_minimum_size = Vector2(300, 360)
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -150
	pause_panel.offset_top = -180
	pause_panel.offset_right = 150
	pause_panel.offset_bottom = 180
	pause_panel.z_index = 20

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.06, 0.14, 0.98)
	panel_style.border_color = Color(1.0, 0.3, 0.8, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_color = Color(1.0, 0.3, 0.8, 0.3)
	panel_style.shadow_size = 16
	pause_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(pause_panel)

	var margin := MarginContainer.new()
	margin.process_mode = Node.PROCESS_MODE_ALWAYS
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	pause_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.process_mode = Node.PROCESS_MODE_ALWAYS
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.8, 1.0))
	vbox.add_child(title)

	var sep := Control.new()
	sep.process_mode = Node.PROCESS_MODE_ALWAYS
	sep.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(sep)

	resume_button = create_scifi_button("RESUME", Color(0.0, 0.9, 1.0))
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(toggle_pause)
	vbox.add_child(resume_button)

	restart_button = create_scifi_button("RESTART", Color(0.3, 1.0, 0.6))
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(func():
		toggle_pause()
		start_match(game_mode)
	)
	vbox.add_child(restart_button)

	pause_menu_button = create_scifi_button("MAIN MENU", Color(0.7, 0.8, 1.0))
	pause_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu_button.pressed.connect(func():
		toggle_pause()
		show_main_menu()
	)
	vbox.add_child(pause_menu_button)

	pause_quit_button = create_scifi_button("ABORT MISSION", Color(1.0, 0.3, 0.4))
	pause_quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_quit_button.pressed.connect(quit_game)
	vbox.add_child(pause_quit_button)


func toggle_pause() -> void:
	if state == GameState.MENU or state == GameState.MATCH_OVER:
		return

	is_paused = not is_paused

	if is_paused:
		pause_panel.show()
		status_label.hide()
	else:
		pause_panel.hide()
		status_label.show()
		# When unpausing, re-trigger the current round state safely from scratch
		start_round_from_current_state()


func show_ai_menu() -> void:
	main_menu_vbox.hide()
	ai_menu_vbox.show()
	menu_title.text = "SELECT AI"


func show_main_menu_buttons() -> void:
	ai_menu_vbox.hide()
	main_menu_vbox.show()
	menu_title.text = "DRAW!"


func create_scifi_button(text: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 42)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.07, 0.1, 0.22, 0.9)
	normal_style.border_color = accent
	normal_style.set_border_width_all(1)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 0.8)
	hover_style.border_color = accent
	hover_style.set_border_width_all(2)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	hover_style.shadow_color = accent
	hover_style.shadow_size = 8

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = accent
	pressed_style.border_color = Color.WHITE
	pressed_style.set_border_width_all(2)
	pressed_style.corner_radius_top_left = 4
	pressed_style.corner_radius_top_right = 4
	pressed_style.corner_radius_bottom_left = 4
	pressed_style.corner_radius_bottom_right = 4

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 13)

	return btn


func _input(event: InputEvent) -> void:
	if is_paused:
		return

	var pos: Vector2

	if event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		pos = get_global_transform_with_canvas().affine_inverse() * event.position

	elif event is InputEventScreenTouch:
		if not event.pressed:
			return
		pos = get_global_transform_with_canvas().affine_inverse() * event.position

	else:
		return

	if state == GameState.MENU or state == GameState.MATCH_OVER:
		return

	if pause_button.visible and pause_button.get_global_rect().has_point(event.position):
		return

	if game_mode != GameMode.PVP and pos.y < size.y / 2.0:
		return

	handle_tap(pos)


func start_match(mode: GameMode) -> void:
	game_mode = mode
	round_id += 1
	scores = [0, 0]
	reactions = [-1, -1]
	last_reactions = [-1, -1]
	state = GameState.READY
	is_paused = false
	pause_panel.hide()

	menu_panel.hide()
	if credit_label:
		credit_label.hide()
	status_label.show()
	pause_button.show()

	update_background()
	start_round()


func start_round() -> void:
	round_id += 1
	var this_round := round_id

	if ai_timer:
		ai_timer = null

	state = GameState.READY
	reactions = [-1, -1]
	status_label.text = "READY"

	update_background()
	set_background_phase("READY")
	audio_stream_player_2d.play()

	await get_tree().create_timer(1.5).timeout
	if this_round != round_id:
		return
	while is_paused:
		await get_tree().create_timer(0.1).timeout
		if this_round != round_id:
			return

	state = GameState.WAITING
	status_label.text = "STEADY"
	set_background_phase("STEADY")
	audio_stream_player_2d.play()

	await get_tree().create_timer(1.0).timeout
	if this_round != round_id:
		return
	while is_paused:
		await get_tree().create_timer(0.1).timeout
		if this_round != round_id:
			return

	var random_wait := randf_range(1.5, 4.0)
	await get_tree().create_timer(random_wait).timeout
	if this_round != round_id:
		return
	while is_paused:
		await get_tree().create_timer(0.1).timeout
		if this_round != round_id:
			return

	state = GameState.SHOOT
	shoot_time = Time.get_ticks_msec()
	status_label.text = "DRAW!"
	set_background_phase("SHOOT")
	sound_manager.play_explosion()

	if game_mode != GameMode.PVP:
		trigger_ai_reaction(this_round)


func start_round_from_current_state() -> void:
	# Resets the label and phase visuals based on where we paused
	match state:
		GameState.READY:
			status_label.text = "READY"
			set_background_phase("READY")
		GameState.WAITING:
			status_label.text = "STEADY"
			set_background_phase("STEADY")
		GameState.SHOOT:
			status_label.text = "DRAW!"
			set_background_phase("SHOOT")


func trigger_ai_reaction(target_round: int) -> void:
	var delay := 0.35
	match game_mode:
		GameMode.AI_EASY:
			delay = randf_range(0.35, 0.55)
		GameMode.AI_MEDIUM:
			delay = randf_range(0.22, 0.36)
		GameMode.AI_HARD:
			delay = randf_range(0.14, 0.23)

	ai_timer = get_tree().create_timer(delay)
	await ai_timer.timeout

	while is_paused:
		await get_tree().create_timer(0.1).timeout

	if target_round != round_id or state != GameState.SHOOT:
		return
	if reactions[1] != -1:
		return

	handle_tap(Vector2(size.x / 2.0, size.y * 0.27))


func handle_tap(pos: Vector2) -> void:
	if is_paused or state == GameState.ROUND_OVER or state == GameState.MATCH_OVER:
		return

	var player := 0 if pos.y >= size.y / 2.0 else 1

	if state == GameState.READY or state == GameState.WAITING:
		var offender_name := "PLAYER 1" if player == 0 else ("AI" if game_mode != GameMode.PVP else "PLAYER 2")
		var winner := 1 - player
		finish_round(winner, "FALSE START! " + offender_name + " LOSES ROUND!")
		return

	if state != GameState.SHOOT:
		return

	if reactions[player] != -1:
		return

	reactions[player] = Time.get_ticks_msec() - shoot_time
	last_reactions[player] = reactions[player]
	update_background_reactions()

	var p_label := "PLAYER 1" if player == 0 else ("AI" if game_mode != GameMode.PVP else "PLAYER 2")
	status_label.text = p_label + ": " + str(reactions[player]) + " ms"

	finish_round(player, p_label + " DRAWS FIRST!")


func finish_round(winner: int, message: String) -> void:
	if state == GameState.ROUND_OVER or state == GameState.MATCH_OVER:
		return

	state = GameState.ROUND_OVER
	sound_manager.stop_hum()

	if winner >= 0:
		scores[winner] += 1
		audio_stream_player_2d_2.play()

	status_label.text = message
	update_background()

	var background = get_node_or_null("CosmicBackground")
	if background and background.has_method("finish_round_effects"):
		background.finish_round_effects(winner, 3.0)
	else:
		set_background_phase("READY")

	round_id += 1
	var this_round := round_id

	await get_tree().create_timer(3.0).timeout
	if this_round != round_id:
		return
	while is_paused:
		await get_tree().create_timer(0.1).timeout
		if this_round != round_id:
			return

	if scores[0] >= TARGET_WINS or scores[1] >= TARGET_WINS:
		var match_winner := 0 if scores[0] >= TARGET_WINS else 1
		state = GameState.MATCH_OVER
		
		if game_mode != GameMode.PVP:
			if match_winner == 0:
				status_label.text = "YOU WIN THE MATCH!"
			else:
				status_label.text = "AI WINS THE MATCH!"
		else:
			status_label.text = "PLAYER " + str(match_winner + 1) + " WINS THE MATCH!"

		await get_tree().create_timer(1.5).timeout
		if this_round != round_id:
			return
		while is_paused:
			await get_tree().create_timer(0.1).timeout
			if this_round != round_id:
				return

		show_match_over_menu()
	else:
		start_round()


func show_match_over_menu() -> void:
	pause_button.hide()
	var match_winner := 0 if scores[0] >= TARGET_WINS else 1
	if game_mode != GameMode.PVP:
		if match_winner == 0:
			menu_title.text = "YOU WIN!"
		else:
			menu_title.text = "AI WINS!"
	else:
		menu_title.text = "PLAYER " + str(match_winner + 1) + "\nWINS!"

	menu_subtitle.text = "FINAL SCORE: " + str(scores[0]) + " - " + str(scores[1])
	play_button.text = "PLAY AGAIN"
	show_main_menu_buttons()
	menu_button.show()
	menu_panel.show()
	if credit_label:
		credit_label.show()
	status_label.hide()


func show_main_menu() -> void:
	is_paused = false
	round_id += 1
	sound_manager.stop_hum()
	state = GameState.MENU
	scores = [0, 0]
	reactions = [-1, -1]
	last_reactions = [-1, -1]

	status_label.text = ""
	status_label.hide()
	pause_button.hide()
	pause_panel.hide()
	menu_title.text = "DRAW!"
	menu_subtitle.text = "— COSMIC REACTION DUEL —"
	play_button.text = "2P DUEL"
	menu_button.hide()
	show_main_menu_buttons()
	menu_panel.show()
	if credit_label:
		credit_label.show()

	update_background()
	set_background_phase("MENU")


func quit_game() -> void:
	is_paused = false
	get_tree().quit()


func update_background() -> void:
	var background = get_node_or_null("CosmicBackground")
	if background and background.has_method("set_scores"):
		background.set_scores(scores[0], scores[1])
	update_background_reactions()


func update_background_reactions() -> void:
	var background = get_node_or_null("CosmicBackground")
	if background and background.has_method("set_reactions"):
		background.set_reactions(last_reactions[0], last_reactions[1])


func set_background_phase(new_phase: String) -> void:
	var background = get_node_or_null("CosmicBackground")
	if background and background.has_method("set_phase"):
		background.set_phase(new_phase)
