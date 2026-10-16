extends Reference

# =========================================
# ZekaCity - BuildingHitTester.gd
# Godot 3.6
# تشخیص ساختمان زیر نشانگر ماوس
# =========================================


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
		var building_id = building["id"]

		var footprint = building_footprints.get_footprint(
			building_id
		)

		var grid_pos = building["grid"]

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

		var hit_width = 64.0
		var hit_height = 90.0

		match building_id:
			"small_house":
				hit_width = 64.0
				hit_height = 90.0

			"normal_house":
				hit_width = 78.0
				hit_height = 110.0

			"low_apartment":
				hit_width = 88.0
				hit_height = 125.0

			"high_apartment":
				hit_width = 96.0
				hit_height = 145.0

			"residential_tower":
				hit_width = 108.0
				hit_height = 175.0

			_:
				hit_width = max(
					64.0,
					(footprint.x + footprint.y) * 16.0
				)

				hit_height = max(
					90.0,
					(footprint.x + footprint.y) * 24.0 + 35.0
				)

		var half_width = hit_width / 2.0

		var hit_polygon = PoolVector2Array([
			building_pos + Vector2(0, -hit_height),
			building_pos + Vector2(
				half_width * 0.65,
				-hit_height * 0.78
			),
			building_pos + Vector2(
				half_width,
				-hit_height * 0.48
			),
			building_pos + Vector2(half_width, -12),
			building_pos + Vector2(
				half_width * 0.55,
				15
			),
			building_pos + Vector2(0, 28),
			building_pos + Vector2(
				-half_width * 0.55,
				15
			),
			building_pos + Vector2(-half_width, -12),
			building_pos + Vector2(
				-half_width,
				-hit_height * 0.48
			),
			building_pos + Vector2(
				-half_width * 0.65,
				-hit_height * 0.78
			)
		])

		if Geometry.is_point_in_polygon(
			mouse_pos,
			hit_polygon
		):
			var depth = grid_pos.x + grid_pos.y

			if depth >= found_depth:
				found_depth = depth
				found_index = i

	return found_index
