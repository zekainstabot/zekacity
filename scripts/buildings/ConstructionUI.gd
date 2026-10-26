
extends Control

signal building_confirmed(building_id)

const MENU_WIDTH = 620
const MENU_HEIGHT = 390
const CARD_WIDTH = 142
const CARD_HEIGHT = 200
const EDGE_MARGIN = 16
const IMAGE_SIZE = Vector2(104, 94)

const BUILDING_IMAGE_PATHS = {
	"small_house": "res://BuildingImages/small_house.png",
	"normal_house": "res://BuildingImages/normal_house.png",
	"low_apartment": "res://BuildingImages/low_apartment.png",
	"high_apartment": "res://BuildingImages/high_apartment.png",
	"residential_tower": "res://BuildingImages/residential_tower.png",
	"grocery_store": "res://BuildingImages/grocery_store.png",
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
	"road": "🛣",
	"small_house": "⌂",
	"normal_house": "⌂",
	"low_apartment": "▥",
	"high_apartment": "▥",
	"residential_tower": "▥",
	"grocery_store": "▣",
	"bakery": "♨",
	"restaurant": "♨",
	"office": "▤",
	"shopping_mall": "▦",
	"factory": "⚙",
	"mineral_market": "⛏",
	"water_tower": "♨",
	"power_station": "ϟ",
	"sewage_plant": "≋",
	"waste_facility": "♻",
	"school": "✎",
	"university": "✎",
	"clinic": "+",
	"hospital": "+",
	"police_station": "★",
	"fire_station": "♨",
	"city_hall": "⌂",
	"small_park": "♣",
	"playground": "⚽",
	"sports_center": "⚽",
	"cultural_center": "♪",
	"small_warehouse": "▧",
	"medium_warehouse": "▧",
	"large_warehouse": "▧",
	"huge_warehouse": "▧"
}

var selected_category = "All"
var selected_building_id = null
var buildings = []
var font_cache = {}

var main_panel = null
var main_vbox = null
var category_container = null
var building_container = null
var info_label = null

var building_footprints = preload(
	"res://scripts/buildings/BuildingFootprints.gd"
).new()


func _ready():
	set_anchors_and_margins_preset(Control.PRESET_WIDE)
	rect_position = Vector2.ZERO
	rect_size = get_viewport_rect().size

	_load_buildings()
	_build_ui()
	hide()


func _load_buildings():
	buildings.clear()

	if not BuildingData.has_method("get_all_buildings"):
		push_error("ConstructionUI: BuildingData.get_all_buildings() not found")
		return

	var all_data = BuildingData.get_all_buildings()

	if typeof(all_data) != TYPE_DICTIONARY:
		push_error("ConstructionUI: Invalid building data")
		return

	var ids = all_data.keys()
	ids.sort()

	for building_id in ids:
		var data = all_data[building_id]

		if typeof(data) != TYPE_DICTIONARY:
			continue

		var item = data.duplicate(true)
		item["id"] = str(building_id)
		item["icon"] = BUILDING_ICONS.get(str(building_id), "◆")
		buildings.append(item)



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
	main_panel.rect_min_size = Vector2(MENU_WIDTH, MENU_HEIGHT)
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	main_panel.anchor_left = 1.0
	main_panel.anchor_right = 1.0
	main_panel.anchor_top = 1.0
	main_panel.anchor_bottom = 1.0

	main_panel.margin_left = -MENU_WIDTH - EDGE_MARGIN
	main_panel.margin_right = -EDGE_MARGIN
	main_panel.margin_top = -MENU_HEIGHT - EDGE_MARGIN
	main_panel.margin_bottom = -EDGE_MARGIN

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
	title.text = "Construction"
	title.align = Label.ALIGN_CENTER
	title.rect_min_size = Vector2(0, 26)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(title, 18)
	main_vbox.add_child(title)

	var category_scroll = ScrollContainer.new()
	category_scroll.name = "CategoryScroll"
	category_scroll.rect_min_size = Vector2(0, 34)
	category_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	main_vbox.add_child(category_scroll)

	category_container = HBoxContainer.new()
	category_container.name = "CategoryContainer"
	category_container.add_constant_override("separation", 5)
	category_container.mouse_filter = Control.MOUSE_FILTER_STOP
	category_scroll.add_child(category_container)

	_create_category_button("All")

	var categories = []

	for building in buildings:
		var category_name = str(building.get("category", "Other"))

		if not category_name in categories:
			categories.append(category_name)

	categories.sort()

	for category_name in categories:
		_create_category_button(category_name)

	var building_scroll = ScrollContainer.new()
	building_scroll.name = "BuildingScroll"
	building_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	building_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	main_vbox.add_child(building_scroll)

	building_container = HBoxContainer.new()
	building_container.name = "BuildingContainer"
	building_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_container.add_constant_override("separation", 8)
	building_container.mouse_filter = Control.MOUSE_FILTER_STOP
	building_scroll.add_child(building_container)

	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "Choose a building"
	info_label.align = Label.ALIGN_CENTER
	info_label.rect_min_size = Vector2(0, 22)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(info_label, 12)
	main_vbox.add_child(info_label)

	var footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGN_CENTER
	footer.add_constant_override("separation", 12)
	main_vbox.add_child(footer)

	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.rect_min_size = Vector2(100, 28)
	cancel_button.connect("pressed", self, "_on_cancel_pressed")
	footer.add_child(cancel_button)

	var build_button = Button.new()
	build_button.text = "Build"
	build_button.rect_min_size = Vector2(100, 28)
	build_button.connect("pressed", self, "_on_build_pressed")
	footer.add_child(build_button)

	_refresh_building_cards()


func open_menu():
	selected_building_id = null
	selected_category = "All"

	if info_label != null:
		info_label.text = "Choose a building"

	_refresh_building_cards()
	show()
	main_panel.show()
	raise()


func _create_category_button(category_name):
	var button = Button.new()
	button.text = category_name
	button.rect_min_size = Vector2(100, 28)
	button.focus_mode = Control.FOCUS_NONE

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
		var category_name = str(building.get("category", "Other"))

		if selected_category != "All" and category_name != selected_category:
			continue

		var building_id = str(building["id"])

		var card = PanelContainer.new()
		card.name = building_id + "_Card"
		card.rect_min_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card.size_flags_horizontal = Control.SIZE_FILL
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		building_container.add_child(card)

		var card_vbox = VBoxContainer.new()
		card_vbox.add_constant_override("separation", 3)
		card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.mouse_filter = Control.MOUSE_FILTER_STOP
		card.add_child(card_vbox)

		var image_holder = CenterContainer.new()
		image_holder.rect_min_size = Vector2(0, IMAGE_SIZE.y)
		image_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
			fallback_label.text = str(building.get("icon", "◆"))
			fallback_label.align = Label.ALIGN_CENTER
			fallback_label.valign = Label.VALIGN_CENTER
			fallback_label.rect_min_size = IMAGE_SIZE
			fallback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_apply_font(fallback_label, 34)
			image_holder.add_child(fallback_label)

		var name_label = Label.new()
		name_label.text = str(building.get("name", building_id))
		name_label.align = Label.ALIGN_CENTER
		name_label.valign = Label.VALIGN_CENTER
		name_label.autowrap = true
		name_label.rect_min_size = Vector2(0, 34)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_font(name_label, 11)
		card_vbox.add_child(name_label)

		
		var cost_label = Label.new()
		cost_label.text = "Cost: " + str(building.get("cost", 0))
		cost_label.align = Label.ALIGN_CENTER
		cost_label.rect_min_size = Vector2(0, 18)
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_font(cost_label, 11)
		card_vbox.add_child(cost_label)

		var required_population = int(
			building.get("population_required", 0)
		)

		var population_label = Label.new()
		population_label.name = "RequiredPopulation"
		population_label.text = "Required Pop: " + str(required_population)
		population_label.align = Label.ALIGN_CENTER
		population_label.rect_min_size = Vector2(0, 20)
		population_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		population_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_font(population_label, 10)
		card_vbox.add_child(population_label)
		
		var footprint = building_footprints.get_footprint(
			building_id
		)


		var size_label = Label.new()
		size_label.name = "BuildingSize"
		size_label.text = (
			str(int(footprint.x))
			+ " × "
			+ str(int(footprint.y))
		)
		size_label.align = Label.ALIGN_CENTER
		size_label.rect_min_size = Vector2(0, 18)
		size_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_font(size_label, 11)
		card_vbox.add_child(size_label)

		var select_button = Button.new()
		select_button.name = "BuildingButton"

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

		select_button.rect_min_size = Vector2(CARD_WIDTH - 12, 26)
		select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select_button.focus_mode = Control.FOCUS_NONE
		card_vbox.add_child(select_button)


func _on_category_pressed(category_name):
	selected_category = category_name
	selected_building_id = null

	if info_label != null:
		info_label.text = "Choose a building"

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

	hide()


func _on_build_pressed():
	if selected_building_id == null:
		info_label.text = "Select a building first"
		return

	emit_signal("building_confirmed", selected_building_id)
	hide()
