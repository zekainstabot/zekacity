extends Reference

# ZekaCity - BuildingHitTester.gd
# Godot 3.6


func find_building_at_position(
	mouse_pos,
	placed_buildings,
	building_footprints,
	tile_width,
	tile_height,
	center
):
	var found_index = -1
	var found_depth = -INF

	for i in range(placed_buildings.size()):
		var building = placed_buildings[i]
		var building_id = str(building["id"])
		var grid_pos = building["grid"]

		var footprint = building_footprints.get_footprint(
			building_id
		)

		var visual_grid_pos = grid_pos + Vector2(
			(footprint.x - 1.0) / 2.0,
			(footprint.y - 1.0) / 2.0
		)

		var building_pos = center + Vector2(
			(visual_grid_pos.x - visual_grid_pos.y)
				* tile_width / 2.0,
			(visual_grid_pos.x + visual_grid_pos.y)
				* tile_height / 2.0
		)

		# محدودهٔ کف ساختمان بر اساس footprint واقعی
		var ground_width = (
			footprint.x + footprint.y
		) * tile_width / 2.0

		var ground_height = (
			footprint.x + footprint.y
		) * tile_height / 2.0

		# ارتفاع بصری ساختمان؛ فقط برای انتخاب قسمت بالایی تصویر
		var building_height = max(
			90.0,
			ground_height + 35.0
		)

		match building_id:
			"small_house":
				building_height = 90.0
			"normal_house":
				building_height = 110.0
			"low_apartment":
				building_height = 125.0
			"high_apartment":
				building_height = 145.0
			"residential_tower":
				building_height = 175.0

		# محدودهٔ انتخاب از بالای ساختمان تا کف footprint
		var half_width = max(
			ground_width / 2.0,
			32.0
		)

		var hit_polygon = PoolVector2Array([
			building_pos + Vector2(0, -building_height),

			building_pos + Vector2(
				half_width * 0.65,
				-building_height * 0.75
			),

			building_pos + Vector2(
				half_width,
				-ground_height / 2.0
			),

			building_pos + Vector2(
				half_width,
				ground_height / 2.0
			),

			building_pos + Vector2(
				0,
				ground_height
			),

			building_pos + Vector2(
				-half_width,
				ground_height / 2.0
			),

			building_pos + Vector2(
				-half_width,
				-ground_height / 2.0
			),

			building_pos + Vector2(
				-half_width * 0.65,
				-building_height * 0.75
			)
		])

		if Geometry.is_point_in_polygon(
			mouse_pos,
			hit_polygon
		):
			var depth = (
				visual_grid_pos.x + visual_grid_pos.y
			)

			if depth >= found_depth:
				found_depth = depth
				found_index = i

	return found_index
