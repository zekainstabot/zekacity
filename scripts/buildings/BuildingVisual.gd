
extends Node2D

# =========================================
# ZekaCity - BuildingVisual.gd
# Godot 3.6
# رسم مستقل ساختمان‌ها با شفافیت
# =========================================

var world = null
var building_id = ""
var grid_pos = Vector2.ZERO
var building_index = -1
var visual_alpha = 1.0
var drawer = null


func setup(
	world_node,
	new_building_id,
	new_grid_pos,
	new_building_index,
	new_alpha = 1.0
):
	world = world_node
	building_id = new_building_id
	grid_pos = new_grid_pos
	building_index = new_building_index
	visual_alpha = clamp(new_alpha, 0.0, 1.0)

	drawer = _get_drawer(building_id)

	var footprint = world.building_footprints.get_footprint(
		building_id
	)

	var visual_grid_pos = grid_pos + Vector2(
		(footprint.x - 1.0) / 2.0,
		(footprint.y - 1.0) / 2.0
	)

	position = world.grid_to_screen(
		visual_grid_pos,
		Vector2(600, 130)
	)

	z_index = int((grid_pos.x + grid_pos.y) * 10)

	modulate = Color(1.0, 1.0, 1.0, visual_alpha)
	update()


func set_visual_alpha(value):
	visual_alpha = clamp(value, 0.0, 1.0)
	modulate = Color(1.0, 1.0, 1.0, visual_alpha)
	update()



func _get_drawer(id):
	if id in [
		"small_house",
		"normal_house",
		"low_apartment",
		"high_apartment",
		"residential_tower"
	]:
		return world.residential_buildings

	if id in [
		"grocery_store",
		"bakery",
		"restaurant",
		"office",
		"shopping_mall",
		"factory",
		"mineral_market"
	]:
		return world.commercial_buildings

	if id in [
		"small_warehouse",
		"medium_warehouse",
		"large_warehouse",
		"huge_warehouse"
	]:
		return world.warehouse_buildings

	if id in ["school", "university"]:
		return world.education_buildings

	if id in ["clinic", "hospital"]:
		return world.healthcare_buildings

	if id in ["police_station", "fire_station", "city_hall"]:
		return world.public_buildings

	if id in [
		"water_tower",
		"power_station",
		"sewage_plant",
		"waste_facility"
	]:
		return world.utility_buildings

	if id in [
		"small_park",
		"playground",
		"sports_center",
		"cultural_center"
	]:
		return world.recreation_buildings

	return null



func _draw():
	if world == null or drawer == null:
		return

	drawer.draw_building(
		self,
		building_id,
		Vector2.ZERO
	)
