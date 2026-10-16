extends CanvasLayer

# ZekaCity - BuildingActionPanel.gd
# Godot 3.6
# رابط مستقل اقدامات ساختمان

signal building_action_selected(action_id)

var panel = null
var title_label = null
var info_button = null
var move_button = null
var demolish_button = null
var close_button = null


func _ready():
	_build_panel()


func _build_panel():
	panel = PanelContainer.new()
	panel.name = "BuildingActionPanel"
	panel.rect_position = Vector2(20, 100)
	panel.rect_min_size = Vector2(230, 220)
	panel.visible = false
	add_child(panel)

	var layout = VBoxContainer.new()
	panel.add_child(layout)

	title_label = Label.new()
	title_label.text = "Building Actions"
	title_label.align = Label.ALIGN_CENTER
	layout.add_child(title_label)

	info_button = _create_button(
		layout,
		"Building Info",
		1
	)

	move_button = _create_button(
		layout,
		"Move Building",
		2
	)

	demolish_button = _create_button(
		layout,
		"Demolish Building",
		3
	)

	close_button = _create_button(
		layout,
		"Close",
		4
	)


func _create_button(container, button_text, action_id):
	var button = Button.new()
	button.text = button_text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(button)

	button.connect(
		"pressed",
		self,
		"_on_action_button_pressed",
		[action_id]
	)

	return button


func show_for_building(building_name):
	title_label.text = building_name
	panel.visible = true


func hide_panel():
	if panel != null:
		panel.visible = false


func is_panel_visible():
	return panel != null and panel.visible


func _on_action_button_pressed(action_id):
	if action_id == 4:
		hide_panel()
		return

	emit_signal(
		"building_action_selected",
		action_id
	)
