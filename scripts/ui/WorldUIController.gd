
extends Reference

var world = null
var ui = null
var treasury_label = null
var buy_land_button = null
var land_purchase_dialog = null


func initialize(world_node, ui_node):
	world = world_node
	ui = ui_node

	if world == null:
		push_error("WorldUIController: World node not found")
		return {}

	if ui != null:
		_create_treasury_label()
		_create_buy_land_button()
	else:
		push_error("WorldUIController: UI node not found")

	_create_land_purchase_dialog()

	return {
		"treasury_label": treasury_label,
		"buy_land_button": buy_land_button,
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

	var viewport_size = ui.get_viewport().get_visible_rect().size
	var label_width = min(320.0, max(180.0, viewport_size.x - 150.0))

	treasury_label.rect_size = Vector2(label_width, 54)
	treasury_label.rect_min_size = Vector2(label_width, 54)
	treasury_label.rect_position = Vector2(
		max(8.0, viewport_size.x - label_width - 12.0),
		8.0
	)


func _create_buy_land_button():
	buy_land_button = Button.new()
	buy_land_button.name = "BuyLandButton"
	buy_land_button.flat = true
	buy_land_button.text = ""
	buy_land_button.focus_mode = Control.FOCUS_NONE

	if ResourceLoader.exists("res://land.png"):
		buy_land_button.icon = load("res://land.png")

	buy_land_button.expand_icon = false
	buy_land_button.rect_min_size = Vector2(76, 76)
	buy_land_button.visible = false
	buy_land_button.mouse_filter = Control.MOUSE_FILTER_STOP

	buy_land_button.anchor_left = 1.0
	buy_land_button.anchor_right = 1.0
	buy_land_button.anchor_top = 0.0
	buy_land_button.anchor_bottom = 0.0

	buy_land_button.margin_left = -96
	buy_land_button.margin_right = -12
	buy_land_button.margin_top = 112
	buy_land_button.margin_bottom = 196

	ui.add_child(buy_land_button)

	buy_land_button.connect(
		"pressed",
		world,
		"_buy_selected_land"
	)


func _create_land_purchase_dialog():
	land_purchase_dialog = ConfirmationDialog.new()
	land_purchase_dialog.name = "LandPurchaseDialog"

	if ui != null:
		ui.add_child(land_purchase_dialog)
	else:
		world.add_child(land_purchase_dialog)

	land_purchase_dialog.connect(
		"confirmed",
		world,
		"_confirm_land_purchase"
	)


func update_treasury_label():
	if world == null:
		print("MONEY ERROR: World is null")
		return

	if treasury_label == null:
		print("MONEY ERROR: Money label is null")
		return

	if world.city_treasury == null:
		print("MONEY ERROR: City treasury is null")
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
		"Buy land in this 2x2 area?\n"
		+ "Tiles to buy: " + str(tiles_to_buy) + "\n"
		+ "Total price: $" + str(total_price) + "\n"
		+ "Current treasury: $" + str(balance)
	)

	land_purchase_dialog.popup_centered()
