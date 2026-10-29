
extends Control

signal building_confirmed(building_id)

const EDGE_MARGIN = 12
const MENU_WIDTH_RATIO = 0.96
const MENU_HEIGHT_RATIO = 0.78

const CARD_WIDTH = 168
const CARD_HEIGHT = 252
const IMAGE_SIZE = Vector2(112, 88)

const TOUCH_BUTTON_HEIGHT = 52
const CATEGORY_BUTTON_WIDTH = 120

const BUILDING_IMAGE_PATHS = {
	"small_house": "res://BuildingImages/small_house.png",
	"normal_house": "res://BuildingImages/normal_house.png",
	"low_apartment": "res://BuildingImages/low_apartment.png",
	"high_apartment": "res://BuildingImages/high_apartment.png",
	"road_horizontal": "res://BuildingImages/road_straight.png",
	"road_vertical": "res://BuildingImages/road_vertical.png",
	"road": "res://BuildingImages/road_straight.png",
	"residential_tower": "res://BuildingImages/residential_tower.png",
	"grocery_store": "res://BuildingImages/grocery_store.png",
	"stone_mine": "res://BuildingImages/stone_mine.png",
	"iron_mine": "res://BuildingImages/iron_mine.png",
	"bakery": "res://BuildingImages/grocery_store.png",
	"restaurant": "res://BuildingImages/grocery_store.png",
	"office": "res://BuildingImages/high_apartment.png",
	"shopping_mall": "res://BuildingImages/high_apartment.png",
	"factory": "res://BuildingImages/medium_warehouse.png",
	"mineral_market": "res://BuildingImages/iron_mine.png",
	"school": "res://BuildingImages/school.png",
	"university": "res://BuildingImages/high_school.png",
	"clinic": "res://BuildingImages/hospital.png",
	"hospital": "res://BuildingImages/hospital.png",
	"small_park": "res://BuildingImages/small_park.png",
	"small_warehouse": "res://BuildingImages/small_warehouse.png",
	"medium_warehouse": "res://BuildingImages/medium_warehouse.png",
	"large_warehouse": "res://BuildingImages/medium_warehouse.png",
	"power_station": "res://BuildingImages/power_station.png",
	"huge_warehouse": "res://BuildingImages/medium_warehouse.png"
}

const BUILDING_ICONS = {
	"road": "Road",
	"road_horizontal": "Horizontal Road",
	"road_vertical": "Vertical Road",
	"small_house": "House",
	"normal_house": "House",
	"low_apartment": "Apartments",
	"stone_mine": "Stone Mine",
	"iron_mine": "Iron Mine",
	"high_apartment": "Apartments",
	"residential_tower": "Tower",
	"grocery_store": "Shop",
	"bakery": "Bakery",
	"restaurant": "Restaurant",
	"office": "Office",
	"shopping_mall": "Mall",
	"factory": "Factory",
	"mineral_market": "Market",
	"water_tower": "Water",
	"power_station": "Power",
	"sewage_plant": "Sewage",
	"waste_facility": "Waste",
	"school": "School",
	"university": "University",
	"clinic": "Clinic",
	"hospital": "Hospital",
	"police_station": "Police",
	"fire_station": "Fire",
	"city_hall": "City Hall",
	"small_park": "Park",
	"playground": "Playground",
	"sports_center": "Sports",
	"cultural_center": "Culture",
	"small_warehouse": "Small Warehouse",
	"medium_warehouse": "Medium Warehouse",
	"large_warehouse": "Large Warehouse",
	"huge_warehouse": "Huge Warehouse"
}

var selected_category = "All"
var selected_building_id = null
var buildings = []
var font_cache = {}

var main_panel = null
var main_vbox = null
var category_container = null
var building_container = null
var category_scroll = null
var building_scroll = null
var info_label = null

var touch_scroll_index = -1
var touch_scroll_target = null
var touch_scroll_last_position = Vector2.ZERO

var building_footprints = preload(
	"res://scripts/buildings/BuildingFootprints.gd"
).new()


func _ready():
	set_anchors_and_margins_preset(Control.PRESET_WIDE)
	rect_position = Vector2.ZERO
	rect_size = get_viewport_rect().size

	_load_buildings()
	_build_ui()
	_update_panel_size()

	get_viewport().connect(
		"size_changed",
		self,
		"_on_viewport_size_changed"
	)

	hide()


func _load_buildings():
	buildings.clear()

	if not BuildingData.has_method("get_all_buildings"):
		push_error(
			"ConstructionUI: BuildingData.get_all_buildings() not found"
		)
		return

	var all_data = BuildingData.get_all_buildings()

	if typeof(all_data) != TYPE_DICTIONARY:
		push_error("ConstructionUI: Invalid building data")
		return

	var ids = all_data.keys()
	ids.sort()

	for building_id in ids:
		var id = str(building_id)

		# Road entries are added below with their own directions.
		if id == "road" or id == "road_horizontal" or id == "road_vertical":
			continue

		var data = all_data[building_id]

		if typeof(data) != TYPE_DICTIONARY:
			continue

		var item = data.duplicate(true)
		item["id"] = id
		item["icon"] = BUILDING_ICONS.get(id, "Building")

		if id == "stone_mine" or id == "iron_mine":
			item["category"] = "Mining"
			item["name"] = (
				"Stone Mine"
				if id == "stone_mine"
				else "Iron Mine"
			)
			item["cost"] = int(item.get("cost", 1500))
			item["population_required"] = int(
				item.get("population_required", 0)
			)

		buildings.append(item)

	# Add mines even if they are missing from BuildingData.
	var mine_definitions = [
		{
			"id": "stone_mine",
			"name": "Stone Mine",
			"category": "Mining",
			"cost": 1500,
			"population_required": 0,
			"icon": "Stone Mine"
		},
		{
			"id": "iron_mine",
			"name": "Iron Mine",
			"category": "Mining",
			"cost": 1500,
			"population_required": 0,
			"icon": "Iron Mine"
		}
	]

	for mine in mine_definitions:
		var already_exists = false

		for building in buildings:
			if str(building.get("id", "")) == mine["id"]:
				already_exists = true
				break

		if not already_exists:
			buildings.append(mine)

	# Add both road directions.
	var road_definitions = [
		{
			"id": "road_horizontal",
			"name": "Horizontal Road",
			"category": "Roads",
			"cost": 0,
			"population_required": 0,
			"icon": "Horizontal Road"
		},
		{
			"id": "road_vertical",
			"name": "Vertical Road",
			"category": "Roads",
			"cost": 0,
			"population_required": 0,
			"icon": "Vertical Road"
		}
	]

	for road_definition in road_definitions:
		var road_exists = false

		for building in buildings:
			if str(building.get("id", "")) == road_definition["id"]:
				road_exists = true
				break

		if not road_exists:
			buildings.append(road_definition)

	print("CONSTRUCTION BUILDINGS LOADED: ", buildings.size())
	print("STONE MINE AVAILABLE: ", true)
	print("IRON MINE AVAILABLE: ", true)
	print("HORIZONTAL ROAD AVAILABLE: ", true)
	print("VERTICAL ROAD AVAILABLE: ", true)


func _make_font(font_size):
	if font_cache.has(font_size):
		return font_cache[font_size]

	var font_path = "res://assets/fonts/Roboto-Regular.ttf"

	if not ResourceLoader.exists(font_path):
		return null

	var font = DynamicFont.new()
	font.font_data = load(font_path)
	font.size = font_size

	font_cache[font_size] = font
	return font


func _apply_font(control, font_size):
	var font = _make_font(font_size)

	if font != null:
		control.add_font_override("font", font)


func _build_ui():
	main_panel = Panel.new()
	main_panel.name = "ConstructionPanel"
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	main_panel.anchor_left = 0.5
	main_panel.anchor_right = 0.5
	main_panel.anchor_top = 1.0
	main_panel.anchor_bottom = 1.0

	add_child(main_panel)

	main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0

	main_vbox.margin_left = 10
	main_vbox.margin_top = 8
	main_vbox.margin_right = -10
	main_vbox.margin_bottom = -8

	main_vbox.add_constant_override("separation", 5)
	main_vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	main_panel.add_child(main_vbox)

	var title = Label.new()
	title.name = "ConstructionTitle"
	title.text = "Construction"
	title.align = Label.ALIGN_CENTER
	title.rect_min_size = Vector2(0, 30)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(title, 18)
	main_vbox.add_child(title)

	category_scroll = ScrollContainer.new()
	category_scroll.name = "CategoryScroll"
	category_scroll.rect_min_size = Vector2(0, 54)
	category_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	main_vbox.add_child(category_scroll)

	category_container = HBoxContainer.new()
	category_container.name = "CategoryContainer"
	category_container.add_constant_override("separation", 8)
	category_container.mouse_filter = Control.MOUSE_FILTER_PASS
	category_scroll.add_child(category_container)

	_create_category_button("All")

	var categories = []

	for building in buildings:
		var category_name = str(
			building.get("category", "Other")
		)

		if not category_name in categories:
			categories.append(category_name)

	categories.sort()

	for category_name in categories:
		_create_category_button(category_name)

	building_scroll = ScrollContainer.new()
	building_scroll.name = "BuildingScroll"
	building_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	building_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	main_vbox.add_child(building_scroll)

	building_container = HBoxContainer.new()
	building_container.name = "BuildingContainer"
	building_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_container.add_constant_override("separation", 10)
	building_container.mouse_filter = Control.MOUSE_FILTER_PASS
	building_scroll.add_child(building_container)

	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "Choose a building"
	info_label.align = Label.ALIGN_CENTER
	info_label.autowrap = true
	info_label.rect_min_size = Vector2(0, 26)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(info_label, 13)
	main_vbox.add_child(info_label)

	var footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGN_CENTER
	footer.add_constant_override("separation", 14)
	footer.rect_min_size = Vector2(0, 54)
	main_vbox.add_child(footer)

	var cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "Cancel"
	cancel_button.rect_min_size = Vector2(130, TOUCH_BUTTON_HEIGHT)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.focus_mode = Control.FOCUS_NONE
	_apply_font(cancel_button, 16)
	cancel_button.connect(
		"pressed",
		self,
		"_on_cancel_pressed"
	)
	footer.add_child(cancel_button)

	var build_button = Button.new()
	build_button.name = "BuildButton"
	build_button.text = "Build"
	build_button.rect_min_size = Vector2(130, TOUCH_BUTTON_HEIGHT)
	build_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_button.focus_mode = Control.FOCUS_NONE
	_apply_font(build_button, 16)
	build_button.connect(
		"pressed",
		self,
		"_on_build_pressed"
	)
	footer.add_child(build_button)

	_refresh_building_cards()


func _update_panel_size():
	if main_panel == null:
		return

	var viewport_size = get_viewport_rect().size

	var panel_width = min(
		viewport_size.x * MENU_WIDTH_RATIO,
		viewport_size.x - EDGE_MARGIN * 2
	)

	var panel_height = min(
		viewport_size.y * MENU_HEIGHT_RATIO,
		viewport_size.y - EDGE_MARGIN * 2
	)

	panel_width = max(1, panel_width)
	panel_height = max(1, panel_height)

	main_panel.anchor_left = 0.5
	main_panel.anchor_right = 0.5
	main_panel.anchor_top = 1.0
	main_panel.anchor_bottom = 1.0

	main_panel.margin_left = -panel_width / 2.0
	main_panel.margin_right = panel_width / 2.0
	main_panel.margin_top = -panel_height - EDGE_MARGIN
	main_panel.margin_bottom = -EDGE_MARGIN

	main_panel.rect_min_size = Vector2(
		panel_width,
		panel_height
	)

	main_panel.rect_size = Vector2(
		panel_width,
		panel_height
	)


func _on_viewport_size_changed():
	rect_size = get_viewport_rect().size
	_update_panel_size()


func open_menu():
	selected_building_id = null
	selected_category = "All"

	if info_label != null:
		info_label.text = "Choose a building"

	if category_scroll != null:
		category_scroll.scroll_horizontal = 0

	if building_scroll != null:
		building_scroll.scroll_horizontal = 0

	_refresh_building_cards()

	show()
	main_panel.show()
	raise()


func _create_category_button(category_name):
	var button = Button.new()
	button.name = "Category_" + category_name.replace(" ", "_")
	button.text = category_name
	button.rect_min_size = Vector2(
		CATEGORY_BUTTON_WIDTH,
		TOUCH_BUTTON_HEIGHT
	)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	_apply_font(button, 14)

	button.connect(
		"pressed",
		self,
		"_on_category_pressed",
		[category_name]
	)

	category_container.add_child(button)


func _get_building_texture(building_id):
	if not BUILDING_IMAGE_PATHS.has(building_id):
		return null

	var path = BUILDING_IMAGE_PATHS[building_id]

	if ResourceLoader.exists(path):
		return load(path)

	return null


func _refresh_building_cards():
	if building_container == null:
		return

	for child in building_container.get_children():
		building_container.remove_child(child)
		child.queue_free()

	for building in buildings:
		var category_name = str(
			building.get("category", "Other")
		)

		if (
			selected_category != "All"
			and category_name != selected_category
		):
			continue

		var building_id = str(building["id"])

		var card = PanelContainer.new()
		card.name = building_id + "_Card"
		card.rect_min_size = Vector2(
			CARD_WIDTH,
			CARD_HEIGHT
		)
		card.size_flags_horizontal = Control.SIZE_FILL
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		building_container.add_child(card)

		var card_vbox = VBoxContainer.new()
		card_vbox.add_constant_override("separation", 2)
		card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		card.add_child(card_vbox)

		var image_holder = CenterContainer.new()
		image_holder.rect_min_size = Vector2(
			0,
			IMAGE_SIZE.y
		)
		image_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(image_holder)

		var texture = _get_building_texture(building_id)

		if texture != null:
			var image_rect = TextureRect.new()
			image_rect.name = "BuildingImage"
			image_rect.texture = texture
			image_rect.rect_min_size = IMAGE_SIZE
			image_rect.expand = true
			image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			image_holder.add_child(image_rect)
		else:
			var fallback_label = Label.new()
			fallback_label.name = "BuildingImageFallback"
			fallback_label.text = str(
				building.get("icon", "Building")
			)
			fallback_label.align = Label.ALIGN_CENTER
			fallback_label.valign = Label.VALIGN_CENTER
			fallback_label.autowrap = true
			fallback_label.rect_min_size = IMAGE_SIZE
			fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_apply_font(fallback_label, 15)
			image_holder.add_child(fallback_label)

		var name_label = Label.new()
		name_label.name = "BuildingName"
		name_label.text = str(
			building.get("name", building_id)
		)
		name_label.align = Label.ALIGN_CENTER
		name_label.valign = Label.VALIGN_CENTER
		name_label.autowrap = true
		name_label.rect_min_size = Vector2(0, 34)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_font(name_label, 12)
		card_vbox.add_child(name_label)

		var cost_label = Label.new()
		cost_label.name = "BuildingCost"
		cost_label.text = "Cost: " + str(
			building.get("cost", 0)
		)
		cost_label.align = Label.ALIGN_CENTER
		cost_label.rect_min_size = Vector2(0, 20)
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_font(cost_label, 12)
		card_vbox.add_child(cost_label)

		var required_population = int(
			building.get("population_required", 0)
		)

		var population_label = Label.new()
		population_label.name = "RequiredPopulation"
		population_label.text = "Required Pop: " + str(
			required_population
		)
		population_label.align = Label.ALIGN_CENTER
		population_label.autowrap = true
		population_label.rect_min_size = Vector2(0, 22)
		population_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_font(population_label, 11)
		card_vbox.add_child(population_label)

		var footprint = building_footprints.get_footprint(
			building_id
		)

		var size_label = Label.new()
		size_label.name = "BuildingSize"
		size_label.text = (
			str(int(footprint.x))
			+ " x "
			+ str(int(footprint.y))
		)
		size_label.align = Label.ALIGN_CENTER
		size_label.rect_min_size = Vector2(0, 20)
		size_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_font(size_label, 12)
		card_vbox.add_child(size_label)

		var select_button = Button.new()
		select_button.name = "BuildingButton"
		select_button.rect_min_size = Vector2(
			CARD_WIDTH - 12,
			TOUCH_BUTTON_HEIGHT
		)
		select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select_button.focus_mode = Control.FOCUS_NONE
		_apply_font(select_button, 14)

		if selected_building_id == building_id:
			select_button.text = "Selected"
			select_button.disabled = true
		else:
			select_button.text = "Select"
			select_button.connect(
				"pressed",
				self,
				"_on_building_pressed",
				[building_id]
			)

		card_vbox.add_child(select_button)


func _on_category_pressed(category_name):
	selected_category = category_name
	selected_building_id = null

	if info_label != null:
		info_label.text = "Choose a building"

	if building_scroll != null:
		building_scroll.scroll_horizontal = 0

	_refresh_building_cards()


func _on_building_pressed(building_id):
	selected_building_id = building_id

	for building in buildings:
		if str(building["id"]) == str(building_id):
			info_label.text = (
				str(building.get("name", building_id))
				+ " | Cost: "
				+ str(building.get("cost", 0))
				+ " | Required Pop: "
				+ str(building.get("population_required", 0))
			)
			break

	_refresh_building_cards()


func _on_cancel_pressed():
	selected_building_id = null

	if info_label != null:
		info_label.text = "Choose a building"

	touch_scroll_target = null
	touch_scroll_index = -1
	hide()


func _on_build_pressed():
	if selected_building_id == null:
		info_label.text = "Select a building first"
		return

	var building_id = selected_building_id
	touch_scroll_target = null
	touch_scroll_index = -1

	emit_signal("building_confirmed", building_id)
	hide()


func _input(event):
	if not visible or main_panel == null:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if not main_panel.get_global_rect().has_point(
				event.position
			):
				return

			touch_scroll_index = event.index
			touch_scroll_last_position = event.position
			touch_scroll_target = null

			if (
				category_scroll != null
				and category_scroll.get_global_rect().has_point(
					event.position
				)
			):
				touch_scroll_target = category_scroll
				return

			if (
				building_scroll != null
				and building_scroll.get_global_rect().has_point(
					event.position
				)
			):
				touch_scroll_target = building_scroll
				return

		else:
			if event.index == touch_scroll_index:
				touch_scroll_index = -1
				touch_scroll_target = null

	elif event is InputEventScreenDrag:
		if event.index != touch_scroll_index:
			return

		if touch_scroll_target == null:
			return

		var delta = event.position - touch_scroll_last_position

		touch_scroll_target.scroll_horizontal = int(
			max(
				0,
				touch_scroll_target.scroll_horizontal - delta.x
			)
		)

		touch_scroll_last_position = event.position
