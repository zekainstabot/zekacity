
extends Control

# ZekaCity - ConstructionUI.gd
# Godot 3.6

signal building_confirmed(building_id)
signal construction_cancelled

var selected_category = "Houses"
var selected_building_id = ""

var category_buttons = {}
var building_buttons = {}

var category_scroll = null
var building_scroll = null
var category_bar = null
var building_bar = null
var selected_label = null
var confirm_button = null

var categories = {
	"Houses": [
		"small_house",
		"normal_house",
		"low_apartment",
		"high_apartment",
		"residential_tower"
	],
	"Parks": [
		"small_park",
		"playground",
		"sports_center",
		"cultural_center"
	],
	"Education": [
		"school",
		"university"
	],
	"Healthcare": [
		"clinic",
		"hospital"
	],
	"Business": [
		"grocery_store",
		"bakery",
		"restaurant",
		"office",
		"shopping_mall",
		"factory",
		"mineral_market"
	],
	"Utilities": [
		"water_tower",
		"power_station",
		"sewage_plant",
		"waste_facility"
	],
	"Services": [
		"city_hall",
		"police_station",
		"fire_station"
	],
	"Warehouses": [
		"small_warehouse",
		"medium_warehouse",
		"large_warehouse",
		"huge_warehouse"
	]
}

var building_names = {
	"small_house": "Small House",
	"normal_house": "House",
	"low_apartment": "Low-rise Apt.",
	"high_apartment": "High-rise Apt.",
	"residential_tower": "Tower",
	"small_park": "Small Park",
	"playground": "Playground",
	"sports_center": "Sports Center",
	"cultural_center": "Culture Center",
	"school": "School",
	"university": "University",
	"clinic": "Clinic",
	"hospital": "Hospital",
	"grocery_store": "Grocery",
	"bakery": "Bakery",
	"restaurant": "Restaurant",
	"office": "Office",
	"shopping_mall": "Shopping Mall",
	"factory": "Factory",
	"mineral_market": "Mineral Market",
	"water_tower": "Water Tower",
	"power_station": "Power Station",
	"sewage_plant": "Sewage Plant",
	"waste_facility": "Waste Facility",
	"city_hall": "City Hall",
	"police_station": "Police",
	"fire_station": "Fire Station",
	"small_warehouse": "Small Storage",
	"medium_warehouse": "Medium Storage",
	"large_warehouse": "Large Storage",
	"huge_warehouse": "Huge Storage"
}

var building_colors = {
	"Houses": Color(0.25, 0.58, 0.88),
	"Parks": Color(0.22, 0.65, 0.39),
	"Education": Color(0.75, 0.56, 0.22),
	"Healthcare": Color(0.82, 0.30, 0.34),
	"Business": Color(0.56, 0.40, 0.82),
	"Utilities": Color(0.20, 0.66, 0.70),
	"Services": Color(0.80, 0.48, 0.25),
	"Warehouses": Color(0.43, 0.51, 0.59)
}

var building_icons = {
	"small_house": "H1",
	"normal_house": "H2",
	"low_apartment": "A1",
	"high_apartment": "A2",
	"residential_tower": "T",
	"small_park": "P",
	"playground": "PLAY",
	"sports_center": "SPORT",
	"cultural_center": "ART",
	"school": "SCH",
	"university": "UNI",
	"clinic": "MED",
	"hospital": "H+",
	"grocery_store": "SHOP",
	"bakery": "BAKE",
	"restaurant": "FOOD",
	"office": "OFF",
	"shopping_mall": "MALL",
	"factory": "IND",
	"mineral_market": "ORE",
	"water_tower": "H2O",
	"power_station": "PWR",
	"sewage_plant": "WTR",
	"waste_facility": "REC",
	"city_hall": "CITY",
	"police_station": "POL",
	"fire_station": "FIRE",
	"small_warehouse": "S",
	"medium_warehouse": "M",
	"large_warehouse": "L",
	"huge_warehouse": "XL"
}


func _ready():
	name = "ConstructionUI"
	_build_interface()
	hide()


func _build_interface():
	anchor_left = 0.02
	anchor_right = 0.98
	anchor_top = 1.0
	anchor_bottom = 1.0

	margin_left = 0
	margin_right = 0
	margin_top = -390
	margin_bottom = -18

	rect_min_size = Vector2(0, 372)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var background = Panel.new()
	background.name = "MenuBackground"
	background.set_anchors_and_margins_preset(
		Control.PRESET_WIDE
	)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.085, 0.12, 0.98)
	panel_style.border_color = Color(0.20, 0.38, 0.52, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12

	background.add_stylebox_override("panel", panel_style)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var main = VBoxContainer.new()
	main.name = "MainLayout"
	main.set_anchors_and_margins_preset(
		Control.PRESET_WIDE
	)
	main.margin_left = 14
	main.margin_top = 12
	main.margin_right = -14
	main.margin_bottom = -12
	main.add_constant_override("separation", 10)
	add_child(main)

	var heading = Label.new()
	heading.text = "BUILD YOUR CITY"
	heading.rect_min_size = Vector2(0, 42)
	heading.align = Label.ALIGN_CENTER
	heading.add_font_override("font", _make_font(30))
	heading.add_color_override(
		"font_color",
		Color(0.88, 0.94, 1.0)
	)
	main.add_child(heading)

	category_scroll = ScrollContainer.new()
	category_scroll.name = "CategoryScroll"
	category_scroll.rect_min_size = Vector2(0, 66)
	category_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_scroll.scroll_horizontal_enabled = true
	category_scroll.scroll_vertical_enabled = false
	main.add_child(category_scroll)

	category_bar = HBoxContainer.new()
	category_bar.name = "CategoryBar"
	category_bar.add_constant_override("separation", 10)
	category_scroll.add_child(category_bar)

	for category in categories.keys():
		var button = Button.new()
		button.text = category
		button.rect_min_size = Vector2(150, 58)
		button.add_font_override("font", _make_font(23))
		button.focus_mode = Control.FOCUS_NONE

		button.connect(
			"pressed",
			self,
			"_on_category_pressed",
			[category]
		)

		category_bar.add_child(button)
		category_buttons[category] = button

	building_scroll = ScrollContainer.new()
	building_scroll.name = "BuildingScroll"
	building_scroll.rect_min_size = Vector2(0, 154)
	building_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_scroll.scroll_horizontal_enabled = true
	building_scroll.scroll_vertical_enabled = false
	main.add_child(building_scroll)

	building_bar = HBoxContainer.new()
	building_bar.name = "BuildingBar"
	building_bar.add_constant_override("separation", 12)
	building_scroll.add_child(building_bar)

	var footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.rect_min_size = Vector2(0, 64)
	footer.add_constant_override("separation", 12)
	main.add_child(footer)

	selected_label = Label.new()
	selected_label.text = "Select a building"
	selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_label.valign = Label.VALIGN_CENTER
	selected_label.add_font_override("font", _make_font(22))
	selected_label.add_color_override(
		"font_color",
		Color(0.85, 0.91, 1.0)
	)
	footer.add_child(selected_label)

	var cancel_button = Button.new()
	cancel_button.text = "CANCEL"
	cancel_button.rect_min_size = Vector2(120, 56)
	cancel_button.add_font_override("font", _make_font(22))
	cancel_button.focus_mode = Control.FOCUS_NONE
	cancel_button.connect(
		"pressed",
		self,
		"_on_cancel_pressed"
	)
	footer.add_child(cancel_button)

	confirm_button = Button.new()
	confirm_button.text = "BUILD"
	confirm_button.rect_min_size = Vector2(132, 56)
	confirm_button.add_font_override("font", _make_font(22))
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.disabled = true
	confirm_button.connect(
		"pressed",
		self,
		"_on_confirm_pressed"
	)
	footer.add_child(confirm_button)

	_refresh_building_cards()
	_update_category_buttons()


func _on_category_pressed(category):
	selected_category = category
	selected_building_id = ""

	selected_label.text = "Select a building"
	confirm_button.disabled = true

	_refresh_building_cards()
	_update_category_buttons()

	building_scroll.scroll_horizontal = 0


func _refresh_building_cards():
	if building_bar == null:
		return

	for child in building_bar.get_children():
		building_bar.remove_child(child)
		child.queue_free()

	building_buttons.clear()

	var items = categories.get(selected_category, [])
	var icon_color = building_colors.get(
		selected_category,
		Color(0.25, 0.5, 0.8)
	)

	for building_id in items:
		var card = VBoxContainer.new()
		card.name = building_id + "_Card"
		card.rect_min_size = Vector2(148, 144)
		card.add_constant_override("separation", 6)
		building_bar.add_child(card)

		var icon_panel = Panel.new()
		icon_panel.rect_min_size = Vector2(0, 66)
		card.add_child(icon_panel)

		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = icon_color
		icon_style.corner_radius_top_left = 8
		icon_style.corner_radius_top_right = 8
		icon_style.corner_radius_bottom_left = 8
		icon_style.corner_radius_bottom_right = 8
		icon_panel.add_stylebox_override("panel", icon_style)

		var icon_label = Label.new()
		icon_label.text = building_icons.get(
			building_id,
			"?"
		)
		icon_label.align = Label.ALIGN_CENTER
		icon_label.valign = Label.VALIGN_CENTER
		icon_label.set_anchors_and_margins_preset(
			Control.PRESET_WIDE
		)
		icon_label.add_color_override(
			"font_color",
			Color(1, 1, 1)
		)
		icon_label.add_font_override(
			"font",
			_make_font(25)
		)
		icon_panel.add_child(icon_label)

		var building_button = Button.new()
		building_button.text = building_names.get(
			building_id,
			building_id.replace("_", " ").capitalize()
		)
		building_button.rect_min_size = Vector2(148, 70)
		building_button.add_font_override("font", _make_font(19))
		building_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		building_button.focus_mode = Control.FOCUS_NONE
		building_button.connect(
			"pressed",
			self,
			"_on_building_pressed",
			[building_id]
		)
		card.add_child(building_button)

		building_buttons[building_id] = building_button


func _on_building_pressed(building_id):
	selected_building_id = building_id

	selected_label.text = building_names.get(
		building_id,
		building_id.replace("_", " ").capitalize()
	)

	confirm_button.disabled = false

	for id in building_buttons.keys():
		building_buttons[id].modulate = Color(1, 1, 1, 1)

	if building_buttons.has(building_id):
		building_buttons[building_id].modulate = Color(
			0.65,
			0.88,
			1.0,
			1.0
		)


func _update_category_buttons():
	for category in category_buttons.keys():
		var button = category_buttons[category]

		if category == selected_category:
			button.modulate = Color(0.55, 0.85, 1.0, 1.0)
		else:
			button.modulate = Color(1, 1, 1, 1)


func _make_font(font_size):
	var font_path = "res://assets/fonts/Roboto-Regular.ttf"

	if not ResourceLoader.exists(font_path):
		return null

	var font = DynamicFont.new()
	font.font_data = load(font_path)
	font.size = font_size
	return font

func _on_confirm_pressed():
	if selected_building_id == "":
		return

	emit_signal(
		"building_confirmed",
		selected_building_id
	)

	hide()


func _on_cancel_pressed():
	selected_building_id = ""
	emit_signal("construction_cancelled")
	hide()


func open_menu():
	selected_building_id = ""
	selected_label.text = "Select a building"
	confirm_button.disabled = true

	_refresh_building_cards()
	_update_category_buttons()

	show()
	raise()
