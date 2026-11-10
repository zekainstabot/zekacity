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


func _ready():
	_build_loading_screen()
	set_process(true)
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

	# Subtle isometric city pattern.
	var pattern = Node2D.new()
	pattern.set_script(load("res://scripts/ui/LoadingCityPattern.gd"))
	add_child(pattern)

	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel = PanelContainer.new()
	panel.rect_min_size = Vector2(520, 330)
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
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.set("custom_constants/separation", 15)
	panel.add_child(layout)

	var emblem = Label.new()
	emblem.text = "◆"
	emblem.align = Label.ALIGN_CENTER
	emblem.add_color_override("font_color", Color(0.25, 0.9, 0.82))
	emblem.add_font_size_override("font_size", 42)
	layout.add_child(emblem)

	var title = Label.new()
	title.text = "ZEKA CITY"
	title.align = Label.ALIGN_CENTER
	title.add_color_override("font_color", Color(0.94, 0.98, 1.0))
	title.add_font_size_override("font_size", 34)
	layout.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Build your world. Shape your future."
	subtitle.align = Label.ALIGN_CENTER
	subtitle.add_color_override("font_color", Color(0.57, 0.75, 0.82))
	subtitle.add_font_size_override("font_size", 15)
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
	percent_label.add_font_size_override("font_size", 13)
	layout.add_child(percent_label)

	retry_button = Button.new()
	retry_button.text = "تلاش دوباره"
	retry_button.visible = false
	retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_button.connect("pressed", self, "_on_retry_pressed")
	layout.add_child(retry_button)


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
