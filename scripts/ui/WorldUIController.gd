
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
		push_error("WorldUIController: World node NOT FOUND")
		return {}

	if ui != null:
		_create_treasury_label()
		_create_buy_land_button()
	else:
		push_error("WorldUIController: UI node NOT FOUND")

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
	treasury_label.anchor_left = 1.0
	treasury_label.anchor_right = 1.0
	treasury_label.margin_left = -460
	treasury_label.margin_right = -20
	treasury_label.margin_top = 18
	treasury_label.margin_bottom = 98
	treasury_label.align = Label.ALIGN_LEFT
	treasury_label.valign = Label.VALIGN_CENTER

	var money_font = DynamicFont.new()
	var money_font_path = "res://assets/fonts/Roboto-Regular.ttf"
	if ResourceLoader.exists(money_font_path):
		money_font.font_data = load(money_font_path)
	money_font.size = 28
	treasury_label.add_font_override("font", money_font)

	treasury_label.add_color_override(
		"font_color",
		Color(1, 1, 0.3, 1)
	)

	ui.add_child(treasury_label)
	treasury_label.raise()


func _create_buy_land_button():
	buy_land_button = Button.new()
	buy_land_button.flat = true
	buy_land_button.name = "BuyLandButton"
	buy_land_button.text = ""
	buy_land_button.icon = load("res://land.png")
	buy_land_button.expand_icon = false
	buy_land_button.rect_min_size = Vector2(104, 104)
	buy_land_button.visible = false
	buy_land_button.anchor_left = 1.0
	buy_land_button.anchor_right = 1.0
	buy_land_button.margin_left = -224
	buy_land_button.margin_right = -24
	buy_land_button.margin_top = 112
	buy_land_button.margin_bottom = 208

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
	if world == null or treasury_label == null:
		return

	if world.city_treasury == null:
		return

	treasury_label.text = "Money: $" + str(
		world.city_treasury.get_balance()
	)


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
