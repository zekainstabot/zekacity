extends Control

# ZekaCity - Boot.gd
# Godot 3.6: loads the actual game scene incrementally and displays progress.

const GAME_SCENE_PATH = "res://Main.tscn"

var loader = null
var progress_bar = null
var status_label = null
var percent_label = null
var retry_button = null
var loading_failed = false
var launch_started = false
var ui_font_data = null




func _draw():
	var viewport_size = get_viewport_rect().size
	var width = max(viewport_size.x, 640.0)
	var height = max(viewport_size.y, 480.0)

	# Subtle isometric grid in the background.
	var grid_color = Color(0.18, 0.48, 0.56, 0.12)
	var spacing = 58.0
	var diagonal = width + height

	for offset in range(-int(diagonal), int(diagonal), int(spacing)):
		draw_line(
			Vector2(offset, 0),
			Vector2(offset + height, height),
			grid_color,
			1.0,
			true
		)
		draw_line(
			Vector2(offset, 0),
			Vector2(offset - height, height),
			grid_color,
			1.0,
			true
		)

	# Decorative low-poly skyline, kept behind the loading panel.
	var base_y = height * 0.80
	var building_width = 76.0

	for i in range(-2, int(width / building_width) + 3):
		var x = float(i) * building_width + 12.0
		var wave = sin(float(i) * 1.7) * 10.0
		var building_height = 70.0 + float(abs(i * 37) % 90)
		var top_y = base_y - building_height + wave

		var front = PoolVector2Array([
			Vector2(x, top_y + 22.0),
			Vector2(x + 38.0, top_y + 42.0),
			Vector2(x + 38.0, base_y + 20.0),
			Vector2(x, base_y)
		])
		var side = PoolVector2Array([
			Vector2(x + 38.0, top_y + 42.0),
			Vector2(x + 66.0, top_y + 26.0),
			Vector2(x + 66.0, base_y + 4.0),
			Vector2(x + 38.0, base_y + 20.0)
		])
		var roof = PoolVector2Array([
			Vector2(x, top_y + 22.0),
			Vector2(x + 28.0, top_y + 6.0),
			Vector2(x + 66.0, top_y + 26.0),
			Vector2(x + 38.0, top_y + 42.0)
		])

		draw_colored_polygon(front, Color(0.07, 0.22, 0.32, 0.72))
		draw_colored_polygon(side, Color(0.04, 0.14, 0.23, 0.78))
		draw_colored_polygon(roof, Color(0.11, 0.32, 0.42, 0.80))

		for row in range(2):
			for col in range(2):
				var window_x = x + 9.0 + col * 15.0
				var window_y = top_y + 53.0 + row * 22.0
				if window_y < base_y - 8.0:
					draw_rect(
						Rect2(Vector2(window_x, window_y), Vector2(5, 8)),
						Color(0.20, 0.82, 0.75, 0.30)
					)

	# A small animated highlight line gives the background a living feel.
	var glow_x = fposmod(OS.get_ticks_msec() / 45.0, width + 220.0) - 110.0
	draw_line(
		Vector2(glow_x, base_y + 28.0),
		Vector2(glow_x + 130.0, base_y + 28.0),
		Color(0.12, 0.78, 0.73, 0.18),
		2.0,
		true
	)


func _ready():
	var font_path = "res://assets/fonts/Roboto-Regular.ttf"
	if ResourceLoader.exists(font_path):
		ui_font_data = load(font_path)

	_build_loading_screen()
	set_process(true)
	set_process_input(false)
	call_deferred("_start_loading")


func _process(_delta):
	if loader == null or loading_failed or launch_started:
		return

	var error = loader.poll()

	if error == ERR_FILE_EOF:
		_finish_loading()
		return

	if error != OK:
		_show_loading_error(error)
		return

	var total_stages = max(1, loader.get_stage_count())
	var current_stage = loader.get_stage()
	var percent = clamp(
		float(current_stage) / float(total_stages) * 100.0,
		0.0,
		99.0
	)

	progress_bar.value = percent
	percent_label.text = str(int(percent)) + "%"
	status_label.text = _get_loading_message(percent)


func _build_loading_screen():
	# Deep blue background.
	var background = ColorRect.new()
	background.color = Color(0.025, 0.055, 0.105, 1.0)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel = PanelContainer.new()
	var screen_width = get_viewport_rect().size.x
	panel.rect_min_size = Vector2(
		max(280.0, min(520.0, screen_width - 32.0)),
		330
	)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.105, 0.17, 0.97)
	panel_style.border_color = Color(0.12, 0.72, 0.72, 0.9)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(18)
	panel_style.content_margin_left = 34
	panel_style.content_margin_right = 34
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	panel.add_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var layout = VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGN_CENTER
	layout.set("custom_constants/separation", 15)
	panel.add_child(layout)

	var emblem = Label.new()
	emblem.text = "◆"
	emblem.align = Label.ALIGN_CENTER
	emblem.add_color_override("font_color", Color(0.25, 0.9, 0.82))
	_apply_font(emblem, 42)
	layout.add_child(emblem)

	var title = Label.new()
	title.text = "ZEKA CITY"
	title.align = Label.ALIGN_CENTER
	title.add_color_override("font_color", Color(0.94, 0.98, 1.0))
	_apply_font(title, 34)
	layout.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Build your world. Shape your future."
	subtitle.align = Label.ALIGN_CENTER
	subtitle.add_color_override("font_color", Color(0.57, 0.75, 0.82))
	_apply_font(subtitle, 15)
	layout.add_child(subtitle)

	var spacer = Control.new()
	spacer.rect_min_size.y = 8
	layout.add_child(spacer)

	status_label = Label.new()
	status_label.text = "در حال آماده‌سازی شهر شما..."
	status_label.align = Label.ALIGN_CENTER
	status_label.add_color_override("font_color", Color(0.84, 0.93, 0.96))
	layout.add_child(status_label)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.percent_visible = false
	progress_bar.rect_min_size = Vector2(0, 13)

	var progress_style = StyleBoxFlat.new()
	progress_style.bg_color = Color(0.10, 0.19, 0.27)
	progress_style.set_corner_radius_all(7)
	progress_bar.add_stylebox_override("bg", progress_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.12, 0.82, 0.73)
	fill_style.set_corner_radius_all(7)
	progress_bar.add_stylebox_override("fg", fill_style)
	layout.add_child(progress_bar)

	percent_label = Label.new()
	percent_label.text = "0%"
	percent_label.align = Label.ALIGN_CENTER
	percent_label.add_color_override("font_color", Color(0.35, 0.88, 0.81))
	_apply_font(percent_label, 13)
	layout.add_child(percent_label)

	retry_button = Button.new()
	retry_button.text = "تلاش دوباره"
	retry_button.visible = false
	retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_button.connect("pressed", self, "_on_retry_pressed")
	layout.add_child(retry_button)


func _apply_font(label, size):
	if ui_font_data == null:
		return

	var font = DynamicFont.new()
	font.font_data = ui_font_data
	font.size = size
	label.add_font_override("font", font)


func _start_loading():
	loading_failed = false
	launch_started = false
	retry_button.visible = false
	progress_bar.value = 0
	percent_label.text = "0%"
	status_label.text = "در حال آماده‌سازی شهر شما..."

	loader = ResourceLoader.load_interactive(GAME_SCENE_PATH)

	if loader == null:
		_show_loading_error(ERR_CANT_OPEN)
		return


func _finish_loading():
	var packed_scene = loader.get_resource() as PackedScene
	loader = null

	if packed_scene == null:
		_show_loading_error(ERR_INVALID_DATA)
		return

	launch_started = true
	progress_bar.value = 100
	percent_label.text = "100%"
	status_label.text = "شهر شما آماده است!"

	# Keep the completed screen visible briefly instead of flashing past it.
	yield(get_tree().create_timer(0.45), "timeout")

	if is_inside_tree():
		var change_error = get_tree().change_scene_to(packed_scene)
		if change_error != OK:
			_show_loading_error(change_error)


func _show_loading_error(error):
	loader = null
	loading_failed = true
	launch_started = false
	status_label.text = "بارگذاری بازی انجام نشد. اتصال فایل‌های بازی را بررسی کنید."
	percent_label.text = "خطا: " + str(error)
	retry_button.visible = true
	push_error("ZekaCity loading failed: " + str(error))


func _on_retry_pressed():
	_start_loading()


func _get_loading_message(percent):
	if percent < 25:
		return "در حال بارگذاری دنیای بازی..."
	elif percent < 50:
		return "در حال آماده‌سازی ساختمان‌ها..."
	elif percent < 75:
		return "در حال چیدن شهر و مسیرها..."
	return "در حال آماده‌سازی آخرین جزئیات..."
