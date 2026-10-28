
extends Reference

# ZekaCity - LandPurchaseController.gd
# Godot 3.6

var world = null
var pending_grid = Vector2.ZERO


func initialize(world_node):
	world = world_node


func request_area_purchase(grid_pos):
	if world == null:
		return

	var origin = world.land_system.get_area_origin(grid_pos)

	if not world.land_system.is_area_adjacent_to_owned(origin):
		return

	var road_system = world.get_node_or_null("../RoadSystem")
	if road_system == null:
		push_error("RoadSystem node NOT FOUND")
		return

	var total_price = world.land_system.get_area_price(
		origin,
		Vector2.ZERO,
		road_system
	)

	if total_price <= 0:
		return

	var tiles_to_buy = 0

	for x in range(int(origin.x), int(origin.x) + 2):
		for y in range(int(origin.y), int(origin.y) + 2):
			var tile = Vector2(x, y)

			if world.land_system.is_inside_map(tile) \
			and not world.land_system.is_owned(tile):
				tiles_to_buy += 1

	if tiles_to_buy == 0:
		return

	if not world.city_treasury.can_afford(total_price):
		print(
			"NOT ENOUGH MONEY. Price: $",
			total_price,
			" | Balance: $",
			world.city_treasury.get_balance()
		)
		return

	pending_grid = origin

	world.world_ui_controller.show_land_purchase_dialog(
		tiles_to_buy,
		total_price,
		world.city_treasury.get_balance()
	)


# سازگاری با دکمهٔ قدیمی تا زمان حذف اتصال آن.
func request_selected_land():
	if world == null:
		return

	request_area_purchase(
		Vector2(world.selected_x, world.selected_y)
	)


func confirm_land_purchase():
	if world == null:
		return

	var road_system = world.get_node_or_null("../RoadSystem")
	if road_system == null:
		push_error("RoadSystem node NOT FOUND")
		return

	# قبل از پرداخت، مجاورت دوباره بررسی می‌شود.
	if not world.land_system.is_area_adjacent_to_owned(pending_grid):
		print("LAND PURCHASE FAILED: AREA_NOT_ADJACENT")
		return

	var result = world.land_purchase.purchase_area(
		pending_grid,
		Vector2.ZERO,
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
		" | Price: $",
		result["price"],
		" | Remaining: $",
		result["balance"]
	)

	world._update_treasury_label()
	world.update()
	world.save_system.save_world(world)

	# پنجرهٔ تأیید بسته می‌شود و رابط محدوده‌ها به‌روزرسانی می‌شود.
	if world.world_ui_controller != null:
		world.world_ui_controller.update_land_purchase_areas()
