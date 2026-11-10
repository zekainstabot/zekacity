
extends CanvasLayer

signal building_action_selected(action_id)
signal market_sell_requested(resource_id, amount)

const EDGE_MARGIN = 12
const TOP_MARGIN = 100
const PANEL_MAX_WIDTH = 460
const BUTTON_HEIGHT = 68

var panel = null
var scroll = null
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
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")


func _build_panel():
	panel = PanelContainer.new()
	panel.name = "BuildingActionPanel"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	scroll = ScrollContainer.new()
	scroll.name = "ActionScroll"
	scroll.rect_min_size = Vector2(0, 0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(scroll)

	var layout = VBoxContainer.new()
	layout.add_constant_override("separation", 10)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(layout)

	title_label = Label.new()
	title_label.text = "Building Actions"
	title_label.align = Label.ALIGN_CENTER
	title_label.autowrap = true
	title_label.rect_min_size = Vector2(0, 58)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_font_override("font", _make_font(26))
	layout.add_child(title_label)

	storage_info_label = Label.new()
	storage_info_label.name = "StorageInfoLabel"
	storage_info_label.autowrap = true
	storage_info_label.rect_min_size = Vector2(0, 100)
	storage_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_info_label.add_font_override("font", _make_font(21))
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

	_update_panel_layout()


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
	button.rect_min_size = Vector2(0, BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_font_override("font", _make_font(22))
	container.add_child(button)
	button.connect("pressed", self, "_on_action_button_pressed", [action_id])
	return button


func _create_market_button(container, button_text, resource_id):
	var button = Button.new()
	button.text = button_text
	button.rect_min_size = Vector2(0, BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_font_override("font", _make_font(21))
	button.visible = false
	container.add_child(button)
	button.connect("pressed", self, "_on_market_button_pressed", [resource_id])
	return button


func _update_panel_layout():
	if panel == null:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var available_width = max(220, viewport_size.x - EDGE_MARGIN * 2)
	var panel_width = min(PANEL_MAX_WIDTH, available_width)
	var available_height = max(180, viewport_size.y - TOP_MARGIN - EDGE_MARGIN)

	panel.rect_size = Vector2(panel_width, 0)
	panel.rect_min_size = Vector2(panel_width, 0)
	panel.rect_position = Vector2(
		(viewport_size.x - panel_width) / 2.0,
		TOP_MARGIN
	)

	panel.rect_size.y = min(
		max(available_height, 180),
		viewport_size.y - TOP_MARGIN - EDGE_MARGIN
	)

	if scroll != null:
		scroll.rect_min_size = Vector2(
			max(0, panel_width - 24),
			max(160, panel.rect_size.y - 20)
		)


func _on_viewport_size_changed():
	_update_panel_layout()


func show_for_building(building_name, target_world = null, building_id = ""):
	title_label.text = str(building_name)
	storage_info_label.visible = false
	storage_info_label.text = ""
	market_stone_button.visible = false
	market_iron_button.visible = false

	if building_id == "" and target_world != null:
		var index = target_world.selected_building_index
		if index >= 0 and index < target_world.placed_buildings.size():
			building_id = str(
				target_world.placed_buildings[index].get("id", "")
			)

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

	# Show the same accounting summary for every business, including
	# the mineral market, without inventing revenue or product prices.
	if target_world != null and _is_business_building(building_id):
		_update_business_finance_info(target_world)
		storage_info_label.visible = true

	_update_panel_layout()
	panel.visible = true
	panel.raise()


func _is_business_building(building_id):
	return str(building_id) in [
		"grocery_store",
		"bakery",
		"restaurant",
		"office",
		"mineral_market",
		"shopping_mall",
		"factory"
	]


func _update_business_finance_info(target_world):
	var index = int(target_world.get("selected_building_index"))

	if index < 0 or index >= target_world.placed_buildings.size():
		return

	var building = target_world.placed_buildings[index]
	var building_id = str(building.get("id", ""))
	var building_grid = building.get("grid", Vector2.ZERO)
	var worker_count = 0
	var is_business = building_id in ["grocery_store", "bakery", "restaurant", "office", "mineral_market", "shopping_mall", "factory", "woodcutter", "sawmill", "carpenter"]
	if not is_business:
		return

	if target_world.citizen_system != null:
		for citizen in target_world.citizen_system.citizens:
			if str(citizen.get("job_id", "")) != building_id:
				continue
			if citizen.get("work_grid", Vector2(-999, -999)) != building_grid:
				continue
			worker_count += 1

	var finance_text = (
		"\n\nBusiness finances:\n"
		+ "Employees: %d\n" % worker_count
		+ "Available business balance: $%d\n" % int(building.get("business_balance", 0))
		+ "Unpaid wages: $%d\n" % int(building.get("unpaid_wages", 0))
		+ "Last revenue: $%d\n" % int(building.get("last_revenue", 0))
		+ "Last wages paid: $%d\n" % int(building.get("last_wages", 0))
		+ "Total revenue: $%d\n" % int(building.get("total_revenue", 0))
		+ "Total wages: $%d\n" % int(building.get("total_wages", 0))
		+ "Total transferred to treasury: $%d" % int(building.get("total_profit", 0))
	)

	storage_info_label.text += finance_text


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
		+ "Wood: %d\n" % int(amounts.get("wood", 0))
		+ "Lumber: %d\n" % int(amounts.get("lumber", 0))
		+ "Furniture: %d\n" % int(amounts.get("furniture", 0))
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
