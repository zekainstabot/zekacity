extends Reference

# ZekaCity - BuildingFootprints.gd
# Godot 3.6

const BuildingData = preload("res://scripts/BuildingData.gd")

var footprints = {}


func _init():
	for building_id in BuildingData.BUILDING_LAYOUTS.keys():
		var dimensions = BuildingData.BUILDING_LAYOUTS[building_id]
		if typeof(dimensions) == TYPE_ARRAY and dimensions.size() == 2:
			footprints[building_id] = Vector2(
				int(dimensions[0]),
				int(dimensions[1])
			)



func get_footprint(building_id):
	return footprints.get(building_id, Vector2(1, 1))


func get_occupied_tiles(building_id, origin):
	var size = get_footprint(building_id)
	var tiles = []

	for x in range(int(size.x)):
		for y in range(int(size.y)):
			tiles.append(origin + Vector2(x, y))

	return tiles


func get_tile_count(building_id):
	var size = get_footprint(building_id)
	return int(size.x) * int(size.y)


func fits_inside_map(building_id, origin, grid_size):
	var size = get_footprint(building_id)

	if origin.x < 0 or origin.y < 0:
		return false

	if origin.x != int(origin.x) or origin.y != int(origin.y):
		return false

	if size.x <= 0 or size.y <= 0:
		return false

	if origin.x + size.x > grid_size:
		return false

	if origin.y + size.y > grid_size:
		return false

	for tile in get_occupied_tiles(building_id, origin):
		if tile.x < 0 or tile.y < 0:
			return false

		if tile.x >= grid_size or tile.y >= grid_size:
			return false

	return true
