
extends Reference

# ZekaCity - LandPurchaseController.gd
# Godot 3.6

var world = null
var pending_grid = Vector2(0, 0)


func initialize(world_node):
	world = world_node


func request_selected_land():
	if world == null:
		push_error("LandPurchaseController: World node NOT FOUND")
		return

	var grid_pos = Vector2(world.selected_x, world.selected_y)
	var city_center = Vector2(0, 0)
	var road_system = world.get_node_or_null("../RoadSystem")

	if road_system == null:
		push_error("RoadSystem node NOT FOUND")
		return

	var start_x = int(floor(grid_pos.x / 2.0)) * 2
	var start_y = int(floor(grid_pos.y / 2.0)) * 2
	var total_price = 0
	var tiles_to_buy = 0

	for x in range(start_x, start_x + 2):
		for y in range(start_y, start_y + 2):
			var tile = Vector2(x, y)

			if not world.land_system.is_inside_map(tile):
				continue

			if not world.land_system.is_owned(tile):
				total_price += world.land_system.get_land_price(
					tile,
					city_center,
					road_system
				)
				tiles_to_buy += 1

	if tiles_to_buy == 0:
		print("LAND PURCHASE FAILED: AREA_ALREADY_OWNED")
		return

	if not world.city_treasury.can_afford(total_price):
		print(
			"NOT ENOUGH MONEY. Price: ",
			total_price,
			" | Balance: $",
			world.city_treasury.get_balance()
		)
		return

	pending_grid = grid_pos

	world.world_ui_controller.show_land_purchase_dialog(
		tiles_to_buy,
		total_price,
		world.city_treasury.get_balance()
	)


func confirm_land_purchase():
	if world == null:
		push_error("LandPurchaseController: World node NOT FOUND")
		return

	var road_system = world.get_node_or_null("../RoadSystem")

	if road_system == null:
		push_error("RoadSystem node NOT FOUND")
		return

	var result = world.land_purchase.purchase_area(
		pending_grid,
		Vector2(0, 0),
		world.land_system,
		world.city_treasury,
		road_system
	)

	if not result.get("success", false):
		print(
			"LAND PURCHASE FAILED: ",
			result.get("error", "UNKNOWN_ERROR")
		)
		return

	print(
		"LAND PURCHASED. Tiles: ",
		result["tiles_bought"],
		" | Price: ",
		result["price"],
		" | Remaining: $",
		result["balance"]
	)

	world._update_treasury_label()

	if world.buy_land_button != null:
		world.buy_land_button.visible = false

	world.update()
	world.save_system.save_world(world)
