extends Node2D

# ZekaCity - shared building rendering standard
# Godot 3.6
#
# Every building is aligned by the visible artwork bounds, not by the
# source image's transparent padding. The footprint controls its world width.
# Keep generated assets isometric, upright, with the building touching the
# bottom-center anchor and without a ground tile/platform.

const GROUND_OFFSET_Y = 0.0
const MAX_BUILDING_HEIGHT_TO_WIDTH = 1.5
const MIN_VISIBLE_ALPHA = 0.05

var world = null
var building_id = ""
var grid_pos = Vector2.ZERO
var building_index = -1
var visual_alpha = 1.0

var building_texture = null
var drawer = null
var has_visible_bounds = false
var visible_bounds = Rect2()


func setup(
	p_world,
	p_building_id,
	p_grid_pos,
	p_building_index = -1,
	p_visual_alpha = 1.0
):
	world = p_world
	building_id = p_building_id
	grid_pos = p_grid_pos
	building_index = p_building_index
	visual_alpha = p_visual_alpha

	var texture_paths = {
		"small_house": "res://BuildingImages/small_house.png",
		"normal_house": "res://BuildingImages/normal_house.png",
		"low_apartment": "res://BuildingImages/low_apartment.png",
		"high_apartment": "res://BuildingImages/high_apartment.png",
		"residential_tower": "res://BuildingImages/residential_tower.png",
		"small_warehouse": "res://BuildingImages/small_warehouse.png",
		"medium_warehouse": "res://BuildingImages/medium_warehouse.png",
		"large_warehouse": "res://BuildingImages/large_warehouse.png",
		"huge_warehouse": "res://BuildingImages/huge_warehouse.png",
		"grocery_store": "res://BuildingImages/grocery_store.png",
		"bakery": "res://BuildingImages/bakery.png",
		"restaurant": "res://BuildingImages/restaurant.png",
		"office": "res://BuildingImages/office.png",
		"shopping_mall": "res://BuildingImages/shopping_mall.png",
		"factory": "res://BuildingImages/factory.png",
		"mineral_market": "res://BuildingImages/mineral_market.png"
	}

	building_texture = null
	has_visible_bounds = false
	visible_bounds = Rect2()

	var texture_path = texture_paths.get(building_id, "")

	if texture_path != "":
		if ResourceLoader.exists(texture_path):
			building_texture = load(texture_path)
		else:
			push_warning("Building texture not found: " + texture_path)

	if building_texture != null:
		var cached_bounds = null

		if world != null and world.building_texture_bounds_cache.has(texture_path):
			cached_bounds = world.building_texture_bounds_cache[texture_path]

		if cached_bounds != null:
			has_visible_bounds = cached_bounds["valid"]
			visible_bounds = cached_bounds["bounds"]
		else:
			_calculate_visible_bounds()
			if world != null:
				world.building_texture_bounds_cache[texture_path] = {
					"valid": has_visible_bounds,
					"bounds": visible_bounds
				}
	else:
		if not (building_id in ["woodcutter", "sawmill", "carpenter"]):
			push_warning("No texture loaded for building: " + building_id)

	var footprint = _get_footprint()
	var visual_grid_pos = grid_pos + Vector2(
		(footprint.x - 1.0) / 2.0,
		(footprint.y - 1.0) / 2.0
	)

	if world != null:
		# Anchor all building art to the south point of its complete footprint.
		var ground_offset = (
			(footprint.x + footprint.y)
			* float(world.tile_height)
			/ 4.0
		)
		position = world.grid_to_screen(
			visual_grid_pos,
			Vector2(600, 130)
		) + Vector2(0, ground_offset)

		# Stable draw ordering from the footprint's center.
		z_index = int(round(visual_grid_pos.x + visual_grid_pos.y))

	modulate = Color(1, 1, 1, visual_alpha)
	update()


func _get_footprint():
	if world != null and world.building_footprints != null:
		return world.building_footprints.get_footprint(building_id)
	return Vector2.ONE


func _calculate_visible_bounds():
	has_visible_bounds = false
	visible_bounds = Rect2()

	if building_texture == null:
		return

	var image = building_texture.get_data()
	if image == null:
		return

	var image_width = image.get_width()
	var image_height = image.get_height()
	if image_width <= 0 or image_height <= 0:
		return

	image.lock()
	var min_x = image_width
	var min_y = image_height
	var max_x = -1
	var max_y = -1

	for y in range(image_height):
		for x in range(image_width):
			if image.get_pixel(x, y).a > MIN_VISIBLE_ALPHA:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)

	image.unlock()

	if max_x < min_x or max_y < min_y:
		return

	visible_bounds = Rect2(
		min_x,
		min_y,
		max_x - min_x + 1,
		max_y - min_y + 1
	)
	has_visible_bounds = true


func _draw():
	if world == null:
		return

	var footprint = _get_footprint()
	var tile_w = float(world.tile_width)
	var tile_h = float(world.tile_height)

	# Projected width of the occupied isometric footprint.
	# This is the same scale rule for every textured building.
	var target_width = max(
		tile_w,
		(footprint.x + footprint.y) * tile_w / 2.0
	)
	var target_height = max(
		tile_h * 2.0,
		target_width * MAX_BUILDING_HEIGHT_TO_WIDTH
	)
	var target_size = Vector2(target_width, target_height)

	if building_texture != null and has_visible_bounds:
		var visible_width = visible_bounds.size.x
		var visible_height = visible_bounds.size.y

		if visible_width <= 0.0 or visible_height <= 0.0:
			return

		# Normalize by visible pixels, not the file canvas. This prevents
		# transparent margins from making otherwise identical buildings
		# appear smaller or shift their ground contact point.
		var scale_factor = min(
			target_width / visible_width,
			target_height / visible_height
		)

		var draw_position = Vector2(
			-visible_bounds.get_center().x * scale_factor,
			-visible_bounds.end.y * -scale_factor + GROUND_OFFSET_Y
		)

		draw_set_transform(
			draw_position,
			0.0,
			Vector2(scale_factor, scale_factor)
		)
		draw_texture(building_texture, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		if building_id in ["woodcutter", "sawmill", "carpenter"]:
			_draw_wood_industry_building()
		elif drawer != null:
			drawer.draw_building(self, building_id, Vector2.ZERO)

	if not world._building_has_road_access(building_id, grid_pos):
		_draw_road_warning(target_size)


func _draw_road_warning(target_size):
	var marker_position = Vector2(0, -target_size.y * 0.75)
	draw_circle(marker_position, 11.0, Color(0.9, 0.12, 0.12, 1))
	draw_line(
		marker_position + Vector2(0, -5),
		marker_position + Vector2(0, 2),
		Color(1, 1, 1, 1),
		2.5,
		true
	)
	draw_circle(
		marker_position + Vector2(0, 6),
		1.5,
		Color(1, 1, 1, 1)
	)


func refresh_road_warning():
	update()


func _draw_wood_industry_building():
	var base_color = Color(0.48, 0.31, 0.18)
	var roof_color = Color(0.30, 0.19, 0.12)

	if building_id == "sawmill":
		base_color = Color(0.56, 0.43, 0.27)
		roof_color = Color(0.38, 0.27, 0.16)
	elif building_id == "carpenter":
		base_color = Color(0.66, 0.48, 0.28)
		roof_color = Color(0.43, 0.29, 0.17)

	# The procedural fallback uses the exact same bottom-center anchor
	# as image assets (the lowest point is local y = 0).
	draw_set_transform(Vector2(0, -18), 0.0, Vector2.ONE)

	draw_colored_polygon(PoolVector2Array([
		Vector2(-38, 0), Vector2(0, 18),
		Vector2(0, -30), Vector2(-38, -48)
	]), base_color.darkened(0.12))
	draw_colored_polygon(PoolVector2Array([
		Vector2(0, 18), Vector2(38, 0),
		Vector2(38, -48), Vector2(0, -30)
	]), base_color)
	draw_colored_polygon(PoolVector2Array([
		Vector2(-40, -48), Vector2(0, -70),
		Vector2(40, -48), Vector2(0, -28)
	]), roof_color)
	draw_rect(
		Rect2(Vector2(-25, -28), Vector2(12, 14)),
		Color(0.25, 0.16, 0.10)
	)
	draw_rect(
		Rect2(Vector2(8, -35), Vector2(15, 12)),
		Color(0.70, 0.83, 0.82)
	)

	if building_id == "sawmill":
		draw_rect(
			Rect2(Vector2(-12, -15), Vector2(24, 8)),
			Color(0.76, 0.62, 0.38)
		)
	elif building_id == "carpenter":
		draw_rect(
			Rect2(Vector2(-12, -18), Vector2(24, 11)),
			Color(0.40, 0.25, 0.13)
		)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
