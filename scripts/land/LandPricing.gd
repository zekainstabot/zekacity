
extends Reference

# ZekaCity - LandPricing.gd
# Godot 3.6
# محاسبه مستقل قیمت زمین

var base_price = 100
var distance_multiplier = 25
var road_discount = 20


func get_land_price(grid_pos, city_center, road_system):
	var distance = abs(grid_pos.x - city_center.x) + abs(grid_pos.y - city_center.y)

	var price = base_price + int(distance * distance_multiplier)

	if road_system != null:
		if _is_near_road(grid_pos, road_system):
			price = max(1, price - road_discount)

	return price


func _is_near_road(grid_pos, road_system):
	var neighbors = [
		grid_pos + Vector2(1, 0),
		grid_pos + Vector2(-1, 0),
		grid_pos + Vector2(0, 1),
		grid_pos + Vector2(0, -1)
	]

	for neighbor in neighbors:
		if road_system.has_road(neighbor):
			return true

	return false
