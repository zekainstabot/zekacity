
extends Reference

# ZekaCity - LandPurchase.gd
# Godot 3.6
# خرید زمین به صورت مربع 2x2

var area_size = 2


func purchase_land(
	grid_pos,
	city_center,
	land_system,
	city_treasury,
	road_system
):
	return purchase_area(
		grid_pos,
		city_center,
		land_system,
		city_treasury,
		road_system
	)


func purchase_area(
	grid_pos,
	city_center,
	land_system,
	city_treasury,
	road_system
):
	var start_x = int(floor(grid_pos.x / float(area_size))) * area_size
	var start_y = int(floor(grid_pos.y / float(area_size))) * area_size

	var area_tiles = []
	var total_price = 0

	for x in range(start_x, start_x + area_size):
		for y in range(start_y, start_y + area_size):
			var tile = Vector2(x, y)

			if not land_system.is_inside_map(tile):
				return {
					"success": false,
					"error": "AREA_OUTSIDE_MAP"
				}

			if not land_system.is_owned(tile):
				var tile_price = land_system.get_land_price(
					tile,
					city_center,
					road_system
				)

				area_tiles.append({
					"grid": tile,
					"price": tile_price
				})

				total_price += tile_price

	if area_tiles.empty():
		return {
			"success": false,
			"error": "AREA_ALREADY_OWNED",
			"price": 0
		}

	if not city_treasury.can_afford(total_price):
		return {
			"success": false,
			"error": "NOT_ENOUGH_MONEY",
			"price": total_price,
			"balance": city_treasury.get_balance()
		}

	if not city_treasury.spend(total_price):
		return {
			"success": false,
			"error": "PAYMENT_FAILED",
			"price": total_price
		}

	for item in area_tiles:
		if not land_system.buy_land(item["grid"]):
			city_treasury.add_money(total_price)

			return {
				"success": false,
				"error": "LAND_PURCHASE_FAILED",
				"price": total_price
			}

	return {
		"success": true,
		"price": total_price,
		"tiles_bought": area_tiles.size(),
		"balance": city_treasury.get_balance(),
		"area_origin": Vector2(start_x, start_y)
	}
