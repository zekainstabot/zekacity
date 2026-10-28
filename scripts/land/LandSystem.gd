
extends Reference

# ZekaCity - LandSystem.gd
# Godot 3.6
# مدیریت مالکیت و محدوده‌های خرید 2x2

var grid_size = 5
var owned_tiles = []

var starting_owned_tiles = [
	Vector2(0, 0),
	Vector2(0, 1),
	Vector2(1, 0),
	Vector2(1, 1)
]

var pricing = preload(
	"res://scripts/land/LandPricing.gd"
).new()


func initialize(size):
	grid_size = max(1, size)
	owned_tiles.clear()

	for tile in starting_owned_tiles:
		if _is_inside_map(tile):
			owned_tiles.append(tile)


func is_inside_map(grid_pos):
	return _is_inside_map(grid_pos)


func is_owned(grid_pos):
	return grid_pos in owned_tiles


func can_buy(grid_pos):
	return _is_inside_map(grid_pos) and not is_owned(grid_pos)


func buy_land(grid_pos):
	if not can_buy(grid_pos):
		return false

	owned_tiles.append(grid_pos)
	return true


func get_land_price(grid_pos, city_center, road_system):
	return pricing.get_land_price(
		grid_pos,
		city_center,
		road_system
	)


# هر محدوده از مختصات زوج شروع می‌شود.
func get_area_origin(grid_pos):
	return Vector2(
		int(floor(grid_pos.x / 2.0)) * 2,
		int(floor(grid_pos.y / 2.0)) * 2
	)


# آیا محدودهٔ 2x2 دست‌کم یک لوزی خریداری‌نشده دارد؟
func area_has_unowned_tiles(grid_pos):
	var origin = get_area_origin(grid_pos)

	for x in range(int(origin.x), int(origin.x) + 2):
		for y in range(int(origin.y), int(origin.y) + 2):
			var tile = Vector2(x, y)

			if _is_inside_map(tile) and not is_owned(tile):
				return true

	return false


# فقط مجاورت مستقیم افقی یا عمودی با زمین مالکیت‌شده معتبر است.
func is_area_adjacent_to_owned(grid_pos):
	var origin = get_area_origin(grid_pos)

	if not area_has_unowned_tiles(origin):
		return false

	for x in range(int(origin.x), int(origin.x) + 2):
		for y in range(int(origin.y), int(origin.y) + 2):
			var tile = Vector2(x, y)

			if not _is_inside_map(tile):
				continue

			var neighbors = [
				tile + Vector2(1, 0),
				tile + Vector2(-1, 0),
				tile + Vector2(0, 1),
				tile + Vector2(0, -1)
			]

			for neighbor in neighbors:
				if not _is_inside_map(neighbor):
					continue

				# همسایهٔ داخل همین محدوده، مجاورت بیرونی نیست.
				var neighbor_origin = get_area_origin(neighbor)
				if neighbor_origin == origin:
					continue

				if is_owned(neighbor):
					return true

	return false


# مجموع قیمت تمام لوزی‌های خریداری‌نشده در محدودهٔ 2x2.
func get_area_price(grid_pos, city_center, road_system):
	var origin = get_area_origin(grid_pos)
	var total_price = 0

	for x in range(int(origin.x), int(origin.x) + 2):
		for y in range(int(origin.y), int(origin.y) + 2):
			var tile = Vector2(x, y)

			if not _is_inside_map(tile):
				continue

			if not is_owned(tile):
				total_price += get_land_price(
					tile,
					city_center,
					road_system
				)

	return total_price


# فهرست محدوده‌های 2x2 القابل خرید؛ فقط محدوده‌های مجاور.
func get_adjacent_purchase_areas():
	var areas = []

	for x in range(0, grid_size, 2):
		for y in range(0, grid_size, 2):
			var origin = Vector2(x, y)

			if area_has_unowned_tiles(origin) \
			and is_area_adjacent_to_owned(origin):
				areas.append(origin)

	return areas


func get_all_tiles():
	var tiles = []

	for x in range(grid_size):
		for y in range(grid_size):
			tiles.append(Vector2(x, y))

	return tiles


func _is_inside_map(grid_pos):
	return (
		grid_pos.x >= 0
		and grid_pos.y >= 0
		and grid_pos.x < grid_size
		and grid_pos.y < grid_size
	)
