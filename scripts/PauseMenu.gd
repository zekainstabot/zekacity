extends Control

const SAVE_PATH = "user://zeka_city_save.json"

var world = null
var overlay = null
var status_label = null
var restart_dialog = null
var pause_panel = null


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	margin_left = 0.0
	margin_top = 0.0
	margin_right = 0.0
	margin_bottom = 0.0

	world = get_node_or_null("/root/main/world")

	_create_pause_overlay()
	_create_restart_dialog()

	get_viewport().connect(
		"size_changed",
		self,
		"_on_viewport_size_changed"
	)


func _create_pause_overlay():
	overlay = ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.color = Color(0.04, 0.08, 0.12, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.margin_left = 0.0
	overlay.margin_top = 0.0
	overlay.margin_right = 0.0
	overlay.margin_bottom = 0.0
	overlay.visible = false
	add_child(overlay)

	pause_panel = PanelContainer.new()
	pause_panel.name = "PausePanel"
	pause_panel.rect_min_size = Vector2(300, 0)
	overlay.add_child(pause_panel)

	var layout = VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGN_CENTER
	layout.add_constant_override("separation", 14)
	layout.anchor_left = 0.0
	layout.anchor_top = 0.0
	layout.anchor_right = 1.0
	layout.anchor_bottom = 1.0
	layout.margin_left = 18
	layout.margin_top = 18
	layout.margin_right = -18
	layout.margin_bottom = -18
	pause_panel.add_child(layout)

	var title = Label.new()
	title.text = "ZEKACITY"
	title.align = Label.ALIGN_CENTER
	title.rect_min_size = Vector2(0, 48)
	layout.add_child(title)

	var resume_button = _make_button("Resume")
	layout.add_child(resume_button)
	resume_button.connect(
		"pressed",
		self,
		"_on_resume_pressed"
	)

	var restart_button = _make_button("Restart")
	layout.add_child(restart_button)
	restart_button.connect(
		"pressed",
		self,
		"_on_restart_pressed"
	)

	var exit_button = _make_button("Exit")
	layout.add_child(exit_button)
	exit_button.connect(
		"pressed",
		self,
		"_on_exit_pressed"
	)

	status_label = Label.new()
	status_label.text = ""
	status_label.align = Label.ALIGN_CENTER
	status_label.autowrap = true
	status_label.rect_min_size = Vector2(0, 52)
	layout.add_child(status_label)

	_update_panel_position()


func _update_panel_position():
	if overlay == null or pause_panel == null:
		return

	var viewport_size = get_viewport_rect().size
	var panel_width = min(330.0, viewport_size.x - 32.0)
	var panel_height = min(410.0, viewport_size.y - 32.0)

	panel_width = max(240.0, panel_width)
	panel_height = max(280.0, panel_height)

	pause_panel.rect_size = Vector2(panel_width, panel_height)
	pause_panel.rect_position = Vector2(
		(viewport_size.x - panel_width) / 2.0,
		(viewport_size.y - panel_height) / 2.0
	)


func _on_viewport_size_changed():
	_update_panel_position()


func _make_button(button_text):
	var button = Button.new()
	button.text = button_text
	button.rect_min_size = Vector2(0, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	return button


func _create_restart_dialog():
	restart_dialog = ConfirmationDialog.new()
	restart_dialog.name = "RestartConfirmation"
	restart_dialog.window_title = "Start a New City"
	restart_dialog.dialog_text = (
		"Start a completely new city?\n\n"
		+ "Your current city will be saved to a separate "
		+ "backup file before the new city starts.\n"
		+ "Continue only if you want a new city."
	)

	restart_dialog.get_ok().text = "Create New City"
	restart_dialog.get_cancel().text = "Cancel"
	add_child(restart_dialog)

	restart_dialog.connect(
		"confirmed",
		self,
		"_on_restart_confirmed"
	)


func _on_pause_pressed():
	if overlay == null:
		return

	if overlay.visible:
		_on_resume_pressed()
	else:
		_update_panel_position()
		status_label.text = ""
		overlay.visible = true
		get_tree().paused = true


func _on_resume_pressed():
	overlay.visible = false
	get_tree().paused = false


func _on_restart_pressed():
	restart_dialog.popup_centered(Vector2(440, 250))


func _on_restart_confirmed():
	if world == null:
		_show_status("Error: World node not found.")
		return

	if not world.has_method("get"):
		_show_status("Error: World is unavailable.")
		return

	var save_system = world.get("save_system")

	if save_system == null:
		_show_status("Error: Save system not found.")
		return

	if not save_system.save_world(world):
		_show_status("Error: Could not save the current city.")
		return

	var source = File.new()

	if not source.file_exists(SAVE_PATH):
		_show_status("Error: Current save file not found.")
		return

	if source.open(SAVE_PATH, File.READ) != OK:
		_show_status("Error: Could not read the current save.")
		return

	var saved_text = source.get_as_text()
	source.close()

	var backup_path = (
		"user://zeka_city_backup_"
		+ str(OS.get_unix_time())
		+ ".json"
	)

	var backup = File.new()

	if backup.open(backup_path, File.WRITE) != OK:
		_show_status("Error: Could not create the city backup.")
		return

	backup.store_string(saved_text)
	var backup_error = backup.get_error()
	backup.close()

	if backup_error != OK:
		_show_status("Error: Backup could not be completed.")
		return

	var directory = Directory.new()
	var remove_error = directory.remove(SAVE_PATH)

	if remove_error != OK:
		_show_status(
			"Backup created, but the old save could not be removed."
		)
		return

	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_pressed():
	if world != null:
		var save_system = world.get("save_system")

		if save_system != null:
			if not save_system.save_world(world):
				_show_status("Warning: The city could not be saved.")
				return

	get_tree().paused = false
	get_tree().quit()


func _show_status(message):
	if status_label != null:
		status_label.text = message
