
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

	treasury_label.anchor_left = 0.0
	treasury_label.anchor_top = 0.0
	treasury_label.anchor_right = 0.0
	treasury_label.anchor_bottom = 0.0

	treasury_label.margin_left = 16
	treasury_label.margin_top = 12
	treasury_label.margin_right = 416
	treasury_label.margin_bottom = 64

	treasury_label.rect_size = Vector2(400, 52)
	treasury_label.rect_min_size = Vector2(400, 52)

	treasury_label.rect_size = Vector2(400, 52)
	treasury_label.rect_min_size = Vector2(400, 52)
	treasury_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	treasury_label.align = Label.ALIGN_CENTER
	treasury_label.valign = Label.VALIGN_CENTER
	treasury_label.autowrap = false
	treasury_label.clip_text = false
	treasury_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	treasury_label.visible = true

	var money_font = DynamicFont.new()
	var money_font_path = "res://assets/fonts/Roboto-Regular.ttf"

	if ResourceLoader.exists(money_font_path):
		money_font.font_data = load(money_font_path)
		money_font.size = 28
		treasury_label.add_font_override("font", money_font)
	else:
		push_warning("Roboto font not found; using Godot default font")

	treasury_label.add_color_override(
		"font_color",
		Color(1, 1, 0.3, 1)
	)

	ui.add_child(treasury_label)
	treasury_label.add_color_override("font_color", Color(1, 0, 0, 1))
	treasury_label.add_color_override("font_color_shadow", Color(0, 0, 0, 1))
	treasury_label.add_constant_override("shadow_offset_x", 2)
	treasury_label.add_constant_override("shadow_offset_y", 2)
	treasury_label.add_constant_override("shadow_as_outline", 1)
	treasury_label.raise()
	print("UI RECT: ", ui.get_viewport().get_visible_rect())
	print("UI LAYER: ", ui.layer)
	print("MONEY GLOBAL RECT: ", treasury_label.get_global_rect())
	print("MONEY MODULATE: ", treasury_label.modulate)
	print("MONEY SELF MODULATE: ", treasury_label.self_modulate)
	print("MONEY FONT COLOR: ", treasury_label.get_color("font_color"))
	print("MONEY PARENT: ", treasury_label.get_parent().name)
	treasury_label.set_as_toplevel(true)
	treasury_label.rect_position = Vector2(16, 12)
	treasury_label.rect_size = Vector2(400, 52)
	treasury_label.visible = true
	treasury_label.show()
	treasury_label.raise()
	treasury_label.add_color_override("font_color", Color(1, 0, 0, 1))
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
		print("MONEY DEBUG: world or label is null")
		return

	if world.city_treasury == null:
		print("MONEY DEBUG: city treasury is null")
		return

	treasury_label.text = "Money: $" + str(
		world.city_treasury.get_balance()
	)

	treasury_label.visible = true
	treasury_label.modulate = Color(1, 1, 0.3, 1)
	treasury_label.raise()

	print("MONEY DEBUG TEXT: ", treasury_label.text)
	print("MONEY DEBUG RECT: ", treasury_label.get_global_rect())
	print("MONEY DEBUG VISIBLE: ", treasury_label.is_visible_in_tree())

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
