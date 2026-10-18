
extends CanvasLayer

# ZekaCity - BuildingActionPanel.gd
# Godot 3.6

signal building_action_selected(action_id)

var panel = null
var title_label = null
var storage_info_label = null
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
	panel.rect_min_size = Vector2(320, 0)
	panel.visible = false
	add_child(panel)

	var layout = VBoxContainer.new()
	layout.add_constant_override("separation", 12)
	panel.add_child(layout)

	title_label = Label.new()
	title_label.text = "Building Actions"
	title_label.align = Label.ALIGN_CENTER
	title_label.rect_min_size = Vector2(300, 48)
	layout.add_child(title_label)

	storage_info_label = Label.new()
	storage_info_label.name = "StorageInfoLabel"
	storage_info_label.autowrap = true
	storage_info_label.rect_min_size = Vector2(300, 100)
	storage_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_info_label.visible = false
	layout.add_child(storage_info_label)

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
	button.rect_min_size = Vector2(300, 76)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(button)

	button.connect(
		"pressed",
		self,
		"_on_action_button_pressed",
		[action_id]
	)

	return button


func show_for_building(building_name, target_world = null, building_id = ""):
	title_label.text = str(building_name)
	storage_info_label.visible = false

	if building_id == "" and target_world != null:
		var index = target_world.selected_building_index

		if index >= 0 and index < target_world.placed_buildings.size():
			building_id = str(
				target_world.placed_buildings[index].get("id", "")
			)

	if target_world != null and (
		_is_warehouse(building_id)
		or _is_warehouse(building_name)
	):
		_update_storage_info(target_world)
		storage_info_label.visible = true

	panel.visible = true
	panel.raise()

	print("STORAGE LABEL VISIBLE: ", storage_info_label.visible)
	print("STORAGE LABEL TEXT: ", storage_info_label.text)


func _is_warehouse(building_id):
	var warehouse_id = str(building_id).to_lower()

	return (
		warehouse_id.find("warehouse") != -1
		or warehouse_id.find("انبار") != -1
	)


func _update_storage_info(target_world):
	var storage = target_world.get("storage_system")
	var resources = target_world.get("resource_manager")

	if storage == null or resources == null:
		storage_info_label.text = "Storage information unavailable."
		return

	var total_capacity = int(storage.get_total_capacity())
	var used_capacity = int(storage.get_used_capacity(resources))
	var free_capacity = max(0, total_capacity - used_capacity)
	var amounts = resources.get_all_amounts()

	storage_info_label.text = (
		"Stone: %d\n" % int(amounts.get("stone", 0))
		+ "Iron ore: %d\n" % int(amounts.get("iron_ore", 0))
		+ "Storage: %d / %d\n" % [used_capacity, total_capacity]
		+ "Free space: %d" % free_capacity
	)


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
