
extends CanvasLayer

signal building_action_selected(action_id)
signal market_sell_requested(resource_id, amount)

var panel = null
var title_label = null
var storage_info_label = null
var market_stone_button = null
var market_iron_button = null
var info_button = null
var move_button = null
var demolish_button = null
var close_button = null


func _ready():
	_build_panel()


func _build_panel():
	panel = PanelContainer.new()
	panel.name = "BuildingActionPanel"
	panel.rect_position = Vector2(20, 110)
	panel.rect_min_size = Vector2(460, 0)
	panel.visible = false
	add_child(panel)

	var layout = VBoxContainer.new()
	layout.add_constant_override("separation", 16)
	panel.add_child(layout)

	title_label = Label.new()
	title_label.text = "Building Actions"
	title_label.align = Label.ALIGN_CENTER
	title_label.rect_min_size = Vector2(420, 68)
	title_label.add_font_override("font", _make_font(30))
	layout.add_child(title_label)

	storage_info_label = Label.new()
	storage_info_label.name = "StorageInfoLabel"
	storage_info_label.autowrap = true
	storage_info_label.rect_min_size = Vector2(420, 180)
	storage_info_label.add_font_override("font", _make_font(24))
	storage_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_info_label.visible = false
	layout.add_child(storage_info_label)

	market_stone_button = _create_market_button(
		layout, "Transfer 1 Stone", "stone"
	)
	market_iron_button = _create_market_button(
		layout, "Transfer 1 Iron Ore", "iron_ore"
	)

	info_button = _create_button(layout, "Building Info", 1)
	move_button = _create_button(layout, "Move Building", 2)
	demolish_button = _create_button(layout, "Demolish Building", 3)
	close_button = _create_button(layout, "Close", 4)


func _make_font(font_size):
	var font = DynamicFont.new()
	var font_path = "res://assets/fonts/Roboto-Regular.ttf"

	if ResourceLoader.exists(font_path):
		font.font_data = load(font_path)

	font.size = font_size
	return font


func _create_button(container, button_text, action_id):
	var button = Button.new()
	button.text = button_text
	button.rect_min_size = Vector2(420, 88)
	button.add_font_override("font", _make_font(25))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(button)
	button.connect("pressed", self, "_on_action_button_pressed", [action_id])
	return button


func _create_market_button(container, button_text, resource_id):
	var button = Button.new()
	button.text = button_text
	button.rect_min_size = Vector2(420, 80)
	button.add_font_override("font", _make_font(24))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.visible = false
	container.add_child(button)
	button.connect("pressed", self, "_on_market_button_pressed", [resource_id])
	return button


func show_for_building(building_name, target_world = null, building_id = ""):
	title_label.text = str(building_name)
	storage_info_label.visible = false
	storage_info_label.text = ""
	market_stone_button.visible = false
	market_iron_button.visible = false

	if building_id == "" and target_world != null:
		var index = target_world.selected_building_index
		if index >= 0 and index < target_world.placed_buildings.size():
			building_id = str(target_world.placed_buildings[index].get("id", ""))

	if target_world != null and (
		_is_warehouse(building_id) or _is_warehouse(building_name)
	):
		_update_storage_info(target_world)
		storage_info_label.visible = true

	elif target_world != null and building_id == "mineral_market":
		var resources = target_world.get("resource_manager")
		var market = target_world.get("mineral_market_system")

		if resources != null and market != null:
			var amounts = resources.get_all_amounts()
			storage_info_label.text = (
				"Mineral Market\n\n"
				+ "Municipal resources:\n"
				+ "Stone: %d\n" % int(amounts.get("stone", 0))
				+ "Iron ore: %d\n\n" % int(amounts.get("iron_ore", 0))
				+ "Market stock:\n"
				+ "Stone: %d\n" % market.get_stock("stone")
				+ "Iron ore: %d\n\n" % market.get_stock("iron_ore")
				+ "Transfer prices:\n"
				+ "Stone: $%d each\n" % market.get_price("stone")
				+ "Iron ore: $%d each" % market.get_price("iron_ore")
			)
			market_stone_button.visible = true
			market_iron_button.visible = true
		else:
			storage_info_label.text = "Market information unavailable."

		storage_info_label.visible = true

	panel.visible = true
	panel.raise()


func _is_warehouse(building_id):
	var value = str(building_id).to_lower()
	return value.find("warehouse") != -1 or value.find("انبار") != -1


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

	emit_signal("building_action_selected", action_id)


func _on_market_button_pressed(resource_id):
	emit_signal("market_sell_requested", resource_id, 1)
