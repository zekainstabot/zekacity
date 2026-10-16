
extends Reference

# ZekaCity - BuildingFootprints.gd
# Godot 3.6
# تعیین ابعاد و تعداد خانه‌های اشغال‌شده توسط هر ساختمان

var footprints = {
	"small_house": Vector2(1, 1),
	"normal_house": Vector2(2, 2),
	"low_apartment": Vector2(2, 2),
	"high_apartment": Vector2(3, 2),
	"residential_tower": Vector2(3, 3),

	"grocery_store": Vector2(2, 2),
	"bakery": Vector2(2, 2),
	"restaurant": Vector2(2, 2),
	"office": Vector2(2, 2),
	"shopping_mall": Vector2(4, 3),
	"factory": Vector2(3, 3),

	"water_tower": Vector2(2, 2),
	"power_station": Vector2(3, 3),
	"sewage_plant": Vector2(3, 3),
	"waste_facility": Vector2(3, 3),

	"school": Vector2(3, 2),
	"university": Vector2(4, 3),
	"clinic": Vector2(2, 2),
	"hospital": Vector2(3, 3),

	"police_station": Vector2(2, 2),
	"fire_station": Vector2(2, 2),
	"city_hall": Vector2(3, 3),

	"small_park": Vector2(2, 2),
	"playground": Vector2(2, 2),
	"sports_center": Vector2(3, 3),
	"cultural_center": Vector2(3, 2)
}


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

	return (
		origin.x >= 0
		and origin.y >= 0
		and origin.x + size.x <= grid_size
		and origin.y + size.y <= grid_size
	)
