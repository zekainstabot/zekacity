
extends Reference

# ZekaCity - WorldUIController.gd
# Godot 3.6

var world = null
var ui = null
var treasury_label = null
var buy_land_button = null
var land_purchase_dialog = null

var area_price_labels = {}
var area_buy_buttons = {}


func initialize(world_node, ui_node):
	world = world_node
	ui = ui_node

	if world == null:
		push_error("WorldUIController: World node not found")
		return {}

	if ui == null:
		push_error("WorldUIController: UI node not found")
		return {}

	_create_treasury_label()
	_create_land_purchase_dialog()

	return {
		"treasury_label": treasury_label,
		"buy_land_button": null,
		"land_purchase_dialog": land_purchase_dialog
	}


func _create_treasury_label():
	treasury_label = Label.new()
	treasury_label.name = "MoneyLabel"
	treasury_label.text = "Money: $" + str(
		world.city_treasury.get_balance()
	)

	var font_path = "res://assets/fonts/Roboto-Regular.ttf"

	if ResourceLoader.exists(font_path):
		var money_font = DynamicFont.new()
		money_font.font_data = load(font_path)
		money_font.size = 26
		treasury_label.add_font_override("font", money_font)

	treasury_label.add_color_override(
		"font_color",
		Color(1, 1, 0.3, 1)
	)

	treasury_label.align = Label.ALIGN_RIGHT
	treasury_label.valign = Label.VALIGN_CENTER
	treasury_label.autowrap = false
	treasury_label.clip_text = true
	treasury_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	ui.add_child(treasury_label)
	treasury_label.set_as_toplevel(true)

	treasury_label.anchor_left = 0.0
	treasury_label.anchor_right = 0.0
	treasury_label.anchor_top = 0.0
	treasury_label.anchor_bottom = 0.0

	_update_treasury_label_layout()
	treasury_label.show()




func _update_treasury_label_layout():
	if treasury_label == null or ui == null:
		return

	var population_label = ui.get_node_or_null("PopulationLabel")

	if population_label != null:
		treasury_label.rect_position = population_label.rect_position - Vector2(0, 55)
	else:
		treasury_label.rect_position = Vector2(20, 15)

	treasury_label.anchor_left = 0.0
	treasury_label.anchor_top = 0.0
	treasury_label.anchor_right = 0.0
	treasury_label.anchor_bottom = 0.0
	treasury_label.rect_size = Vector2(350, 50)


func _create_land_purchase_dialog():
	land_purchase_dialog = ConfirmationDialog.new()
	land_purchase_dialog.name = "LandPurchaseDialog"
	land_purchase_dialog.window_title = "Buy Land"

	ui.add_child(land_purchase_dialog)

	land_purchase_dialog.connect(
		"confirmed",
		world,
		"_confirm_land_purchase"
	)


func update_treasury_label():
	if world == null or treasury_label == null:
		return

	treasury_label.text = "Money: $" + str(
		world.city_treasury.get_balance()
	)

	_update_treasury_label_layout()
	treasury_label.show()
	treasury_label.raise()


func show_land_purchase_dialog(tiles_to_buy, total_price, balance):
	if land_purchase_dialog == null:
		return

	land_purchase_dialog.dialog_text = (
		"Buy this 2x2 land area?\n"
		+ "Unowned tiles: " + str(tiles_to_buy) + "\n"
		+ "Total price: $" + str(total_price) + "\n"
		+ "Treasury: $" + str(balance)
	)

	land_purchase_dialog.popup_centered()


func update_land_purchase_areas():
	if world == null or ui == null:
		return

	var road_system = world.get_node_or_null("../RoadSystem")
	if road_system == null:
		return

	var areas = world.land_system.get_adjacent_purchase_areas()
	var active_keys = {}

	for origin in areas:
		var key = _area_key(origin)
		active_keys[key] = true

		if not area_price_labels.has(key):
			_create_area_controls(origin, key)

		var price = world.land_system.get_area_price(
			origin,
			Vector2.ZERO,
			road_system
		)

		var label = area_price_labels[key]
		var button = area_buy_buttons[key]

		label.text = "$" + str(price)
		_position_area_controls(origin, label, button)

		label.show()
		button.show()

	# محدوده‌هایی که دیگر قابل خرید نیستند پنهان می‌شوند.
	for key in area_price_labels.keys():
		if not active_keys.has(key):
			area_price_labels[key].hide()
			area_buy_buttons[key].hide()


func _area_key(origin):
	return str(int(origin.x)) + "_" + str(int(origin.y))


func _create_area_controls(origin, key):
	var price_label = Label.new()
	price_label.name = "LandPrice_" + key
	price_label.text = "$0"
	price_label.align = Label.ALIGN_CENTER
	price_label.valign = Label.VALIGN_CENTER
	price_label.rect_size = Vector2(100, 30)
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	price_label.add_color_override(
		"font_color",
		Color(1.0, 0.95, 0.45, 1.0)
	)

	var font_path = "res://assets/fonts/Roboto-Regular.ttf"
	if ResourceLoader.exists(font_path):
		var font = DynamicFont.new()
		font.font_data = load(font_path)
		font.size = 18
		price_label.add_font_override("font", font)

	ui.add_child(price_label)
	price_label.set_as_toplevel(true)

	var buy_button = Button.new()
	buy_button.name = "BuyArea_" + key
	buy_button.text = "Buy"
	buy_button.focus_mode = Control.FOCUS_NONE
	buy_button.rect_min_size = Vector2(76, 32)
	buy_button.mouse_filter = Control.MOUSE_FILTER_STOP

	ui.add_child(buy_button)
	buy_button.set_as_toplevel(true)

	buy_button.connect(
		"pressed",
		world.land_purchase_controller,
		"request_area_purchase",
		[origin]
	)

	area_price_labels[key] = price_label
	area_buy_buttons[key] = buy_button


func _position_area_controls(origin, price_label, buy_button):
	# مرکز محدودهٔ 2x2 در مختصات نقشه.
	var map_center = Vector2(600, 130)
	var area_center = world.grid_to_screen(
		origin + Vector2(0.5, 0.5),
		map_center
	)

	# تبدیل مختصات نقشه به مختصات قابل نمایش در UI.
	var screen_position = world.get_global_transform_with_canvas().xform(
		area_center
	)

	price_label.rect_position = screen_position + Vector2(-50, -38)
	buy_button.rect_position = screen_position + Vector2(-38, -6)
