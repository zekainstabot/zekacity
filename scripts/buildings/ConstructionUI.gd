extends Control

const MENU_WIDTH = 560
const MENU_HEIGHT = 310
const CARD_WIDTH = 130
const CARD_HEIGHT = 150

var selected_category = "All"
var selected_building_id = null

var buildings = [
	{
		"id": "house",
		"name": "House",
		"category": "Residential",
		"icon": "🏠",
		"cost": 100
	},
	{
		"id": "shop",
		"name": "Shop",
		"category": "Commercial",
		"icon": "🏪",
		"cost": 200
	},
	{
		"id": "factory",
		"name": "Factory",
		"category": "Industrial",
		"icon": "🏭",
		"cost": 350
	},
	{
		"id": "park",
		"name": "Park",
		"category": "Nature",
		"icon": "🌳",
		"cost": 150
	},
	{
		"id": "school",
		"name": "School",
		"category": "Education",
		"icon": "🏫",
		"cost": 250
	}
]

var main_panel
var main_vbox
var category_container
var building_container
var info_label


func _ready():
	_build_ui()


func _make_font(font_size):
	var font = DynamicFont.new()
	font.font_data = load("res://assets/fonts/Roboto-Regular.ttf")
	font.size = font_size
	return font


func _build_ui():
	main_panel = Panel.new()
	main_panel.name = "ConstructionPanel"
	main_panel.rect_min_size = Vector2(MENU_WIDTH, MENU_HEIGHT)
	main_panel.rect_size = Vector2(MENU_WIDTH, MENU_HEIGHT)
	main_panel.anchor_left = 0.5
	main_panel.anchor_right = 0.5
	main_panel.anchor_top = 0.5
	main_panel.anchor_bottom = 0.5
	main_panel.margin_left = -MENU_WIDTH / 2
	main_panel.margin_right = MENU_WIDTH / 2
	main_panel.margin_top = -MENU_HEIGHT / 2
	main_panel.margin_bottom = MENU_HEIGHT / 2
	add_child(main_panel)

	main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.margin_left = 10
	main_vbox.margin_top = 10
	main_vbox.margin_right = -10
	main_vbox.margin_bottom = -10
	main_vbox.add_constant_override("separation", 6)
	main_panel.add_child(main_vbox)

	var title = Label.new()
	title.text = "Construction"
	title.align = Label.ALIGN_CENTER
	title.rect_min_size = Vector2(0, 28)
	title.add_font_override("font", _make_font(18))
	main_vbox.add_child(title)

	var category_scroll = ScrollContainer.new()
	category_scroll.name = "CategoryScroll"
	category_scroll.rect_min_size = Vector2(0, 38)
	category_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_scroll.size_flags_vertical = 0
	main_vbox.add_child(category_scroll)

	category_container = HBoxContainer.new()
	category_container.name = "CategoryContainer"
	category_container.add_constant_override("separation", 6)
	category_scroll.add_child(category_container)

	_create_category_button("All")
	_create_category_button("Residential")
	_create_category_button("Commercial")
	_create_category_button("Industrial")
	_create_category_button("Nature")
	_create_category_button("Education")

	var building_scroll = ScrollContainer.new()
	building_scroll.name = "BuildingScroll"
	building_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(building_scroll)

	building_container = HBoxContainer.new()
	building_container.name = "BuildingContainer"
	building_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_container.add_constant_override("separation", 8)
	building_scroll.add_child(building_container)

	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "Choose a building"
	info_label.align = Label.ALIGN_CENTER
	info_label.rect_min_size = Vector2(0, 22)
	info_label.add_font_override("font", _make_font(12))
	main_vbox.add_child(info_label)

	var footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGN_CENTER
	footer.add_constant_override("separation", 12)
	main_vbox.add_child(footer)

	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.rect_min_size = Vector2(100, 30)
	cancel_button.connect("pressed", self, "_on_cancel_pressed")
	footer.add_child(cancel_button)

	var build_button = Button.new()
	build_button.text = "Build"
	build_button.rect_min_size = Vector2(100, 30)
	build_button.connect("pressed", self, "_on_build_pressed")
	footer.add_child(build_button)

	_refresh_building_cards()


func _create_category_button(category_name):
	var button = Button.new()
	button.text = category_name
	button.rect_min_size = Vector2(90, 30)
	button.focus_mode = Control.FOCUS_NONE
	button.connect(
		"pressed",
		self,
		"_on_category_pressed",
		[category_name]
	)
	category_container.add_child(button)


func _refresh_building_cards():
	for child in building_container.get_children():
		child.queue_free()

	for building in buildings:
		if selected_category != "All":
			if building["category"] != selected_category:
				continue

		var card = PanelContainer.new()
		card.name = str(building["id"]) + "_Card"
		card.rect_min_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card.rect_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card.size_flags_horizontal = 0
		building_container.add_child(card)

		var card_vbox = VBoxContainer.new()
		card_vbox.add_constant_override("separation", 6)
		card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_child(card_vbox)

		var icon_label = Label.new()
		icon_label.text = str(building["icon"])
		icon_label.align = Label.ALIGN_CENTER
		icon_label.valign = Label.VALIGN_CENTER
		icon_label.rect_min_size = Vector2(0, 35)
		icon_label.add_font_override("font", _make_font(22))
		card_vbox.add_child(icon_label)

		var cost_label = Label.new()
		cost_label.text = "Cost: " + str(building["cost"])
		cost_label.align = Label.ALIGN_CENTER
		cost_label.rect_min_size = Vector2(0, 22)
		cost_label.add_font_override("font", _make_font(11))
		card_vbox.add_child(cost_label)

		var select_button = Button.new()
		select_button.name = "BuildingButton"
		select_button.text = str(building["name"])
		select_button.rect_min_size = Vector2(CARD_WIDTH - 10, 48)
		select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		select_button.focus_mode = Control.FOCUS_NONE
		select_button.autowrap = true

		if selected_building_id == building["id"]:
			select_button.text = str(building["name"]) + "\nSelected"
			select_button.disabled = true
		else:
			select_button.connect(
				"pressed",
				self,
				"_on_building_pressed",
				[building["id"]]
			)

		card_vbox.add_child(select_button)


func _on_category_pressed(category_name):
	selected_category = category_name
	selected_building_id = null
	info_label.text = "Choose a building"
	_refresh_building_cards()


func _on_building_pressed(building_id):
	selected_building_id = building_id

	for building in buildings:
		if building["id"] == building_id:
			info_label.text = (
				str(building["name"])
				+ " | Cost: "
				+ str(building["cost"])
			)
			break

	_refresh_building_cards()


func _on_cancel_pressed():
	selected_building_id = null
	info_label.text = "Choose a building"
	hide()


func _on_build_pressed():
	if selected_building_id == null:
		info_label.text = "Select a building first"
		return

	var selected_building = null

	for building in buildings:
		if building["id"] == selected_building_id:
			selected_building = building
			break

	if selected_building == null:
		return

	emit_signal("building_selected", selected_building)
	hide()


signal building_selected(building_data)
