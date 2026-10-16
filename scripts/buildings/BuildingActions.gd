extends Reference

# ZekaCity - BuildingActions.gd
# Godot 3.6


func demolish_building(building_index, placed_buildings):
	if building_index < 0:
		return {
			"success": false,
			"error": "NO_BUILDING_SELECTED"
		}

	if building_index >= placed_buildings.size():
		return {
			"success": false,
			"error": "BUILDING_NOT_FOUND"
		}

	var building = placed_buildings[building_index]

	if building["id"] == "small_house" and building["grid"] == Vector2(0, 0):
		return {
			"success": false,
			"error": "STARTING_HOUSE_PROTECTED"
		}

	placed_buildings.remove(building_index)

	return {
		"success": true,
		"building": building
	}


func move_building(
	building_index,
	new_origin,
	grid_size,
	placed_buildings,
	footprints,
	land_system,
	road_system,
	allow_move_starting_house = false
):
	if building_index < 0 or building_index >= placed_buildings.size():
		return {
			"success": false,
			"error": "BUILDING_NOT_FOUND"
		}

	var building = placed_buildings[building_index]

	if (
		not allow_move_starting_house
		and building["id"] == "small_house"
		and building["grid"] == Vector2(0, 0)
	):
		return {
			"success": false,
			"error": "STARTING_HOUSE_PROTECTED"
		}

	if not footprints.fits_inside_map(
		building["id"],
		new_origin,
		grid_size
	):
		return {
			"success": false,
			"error": "OUTSIDE_MAP"
		}

	var new_tiles = footprints.get_occupied_tiles(
		building["id"],
		new_origin
	)

	for tile in new_tiles:
		if not land_system.is_owned(tile):
			return {
				"success": false,
				"error": "LAND_NOT_OWNED"
			}

		if road_system != null and road_system.has_road(tile):
			return {
				"success": false,
				"error": "ROAD_OCCUPIED"
			}

		for i in range(placed_buildings.size()):
			if i == building_index:
				continue

			var other_building = placed_buildings[i]
			var other_tiles = footprints.get_occupied_tiles(
				other_building["id"],
				other_building["grid"]
			)

			if tile in other_tiles:
				return {
					"success": false,
					"error": "BUILDING_OCCUPIED"
				}

	placed_buildings[building_index]["grid"] = new_origin

	return {
		"success": true,
		"building": placed_buildings[building_index]
	}
