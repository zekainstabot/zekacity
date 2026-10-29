
extends Reference

# ZekaCity - BuildingPlacement.gd
# Godot 3.6
# بررسی امکان ساخت ساختمان
# دسترسی به جاده مانع ساخت ساختمان نمی‌شود.


func can_place_building(
	building_id,
	origin,
	grid_size,
	placed_buildings,
	footprints,
	land_system,
	road_system
):
	if not footprints.fits_inside_map(
		building_id,
		origin,
		grid_size
	):
		return false

	var new_tiles = footprints.get_occupied_tiles(
		building_id,
		origin
	)

	for tile in new_tiles:
		if not land_system.is_owned(tile):
			return false

		if road_system != null and road_system.has_road(tile):
			return false

		for building in placed_buildings:
			var existing_tiles = footprints.get_occupied_tiles(
				building["id"],
				building["grid"]
			)

			if tile in existing_tiles:
				return false

	return true


func get_placement_error(
	building_id,
	origin,
	grid_size,
	placed_buildings,
	footprints,
	land_system,
	road_system
):
	if not footprints.fits_inside_map(
		building_id,
		origin,
		grid_size
	):
		return "OUTSIDE_MAP"

	var new_tiles = footprints.get_occupied_tiles(
		building_id,
		origin
	)

	for tile in new_tiles:
		if not land_system.is_owned(tile):
			return "LAND_NOT_OWNED"

		if road_system != null and road_system.has_road(tile):
			return "ROAD_OCCUPIED"

		for building in placed_buildings:
			var existing_tiles = footprints.get_occupied_tiles(
				building["id"],
				building["grid"]
			)

			if tile in existing_tiles:
				return "BUILDING_OCCUPIED"

	return "OK"
