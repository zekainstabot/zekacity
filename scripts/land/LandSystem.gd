
extends Reference

# ZekaCity - LandSystem.gd
# Godot 3.6
# مدیریت مالکیت زمین و محاسبه قیمت

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
	if not _is_inside_map(grid_pos):
		return false

	if is_owned(grid_pos):
		return false

	return true


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
