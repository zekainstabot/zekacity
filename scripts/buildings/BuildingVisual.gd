
extends Node2D

const GROUND_OFFSET_Y = 0.0
const BUILDING_SCALE_MULTIPLIER = 1.2
const MINERAL_MARKET_SCALE_MULTIPLIER = 1.0
const MINERAL_MARKET_ANCHOR = Vector2(740.0, 895.0)

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
		"large_warehouse": "res://BuildingImages/medium_warehouse.png",
		"huge_warehouse": "res://BuildingImages/medium_warehouse.png",

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

	var texture_path = ""

	if texture_paths.has(building_id):
		texture_path = texture_paths[building_id]

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
		push_warning("No texture loaded for building: " + building_id)

	var footprint = Vector2.ONE

	if world != null and world.building_footprints != null:
		footprint = world.building_footprints.get_footprint(
			building_id
		)

	var visual_grid_pos = grid_pos + Vector2(
		(footprint.x - 1.0) / 2.0,
		(footprint.y - 1.0) / 2.0
	)

	if world != null:
		var ground_offset = (
			(footprint.x + footprint.y)
			* float(world.tile_height)
			/ 4.0
		)

		position = world.grid_to_screen(
			visual_grid_pos,
			Vector2(600, 130)
		) + Vector2(0, ground_offset)

		z_index = int(round(
			visual_grid_pos.x + visual_grid_pos.y
		))

	modulate = Color(1, 1, 1, visual_alpha)

	update()


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
			if image.get_pixel(x, y).a > 0.05:
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

	var footprint = Vector2.ONE

	if world.building_footprints != null:
		footprint = world.building_footprints.get_footprint(
			building_id
		)

	var tile_w = float(world.tile_width)
	var tile_h = float(world.tile_height)

	var target_size = Vector2(
		max(
			tile_w,
			(footprint.x + footprint.y) * tile_w / 2.0
		),
		max(
			tile_h * 2.0,
			(footprint.x + footprint.y) * tile_h * 1.5
		)
	)

	if building_texture != null:
		var texture_size = building_texture.get_size()

		if texture_size.x <= 0 or texture_size.y <= 0:
			return

		var scale_factor = min(
			target_size.x / texture_size.x,
			target_size.y / texture_size.y
		) * BUILDING_SCALE_MULTIPLIER

		if building_id == "mineral_market":
			scale_factor *= MINERAL_MARKET_SCALE_MULTIPLIER

		var anchor_x = texture_size.x / 2.0
		var anchor_y = texture_size.y

		if has_visible_bounds:
			anchor_x = (
				visible_bounds.position.x
				+ visible_bounds.size.x / 2.0
			)

			anchor_y = visible_bounds.end.y

		if building_id == "mineral_market":
			anchor_x = MINERAL_MARKET_ANCHOR.x
			anchor_y = MINERAL_MARKET_ANCHOR.y

		var draw_position = Vector2(
			-anchor_x * scale_factor,
			-anchor_y * scale_factor + GROUND_OFFSET_Y
		)

		draw_set_transform(
			draw_position,
			0.0,
			Vector2(scale_factor, scale_factor)
		)

		draw_texture(
			building_texture,
			Vector2.ZERO
		)

		draw_set_transform(
			Vector2.ZERO,
			0.0,
			Vector2.ONE
		)

	else:
		if building_id in ["woodcutter", "sawmill", "carpenter"]:
			_draw_wood_industry_building()
		elif drawer != null:
			drawer.draw_building(
				self,
				building_id,
				Vector2.ZERO
			)

	if not world._building_has_road_access(
		building_id,
		grid_pos
	):
		_draw_road_warning(target_size)


func _draw_road_warning(target_size):
	var marker_position = Vector2(
		0,
		-target_size.y * 0.75
	)

	draw_circle(
		marker_position,
		11.0,
		Color(0.9, 0.12, 0.12, 1)
	)

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
	draw_rect(Rect2(Vector2(-25, -28), Vector2(12, 14)), Color(0.25, 0.16, 0.10))
	draw_rect(Rect2(Vector2(8, -35), Vector2(15, 12)), Color(0.70, 0.83, 0.82))
	if building_id == "sawmill":
		draw_rect(Rect2(Vector2(-12, -15), Vector2(24, 8)), Color(0.76, 0.62, 0.38))
	elif building_id == "carpenter":
		draw_rect(Rect2(Vector2(-12, -18), Vector2(24, 11)), Color(0.40, 0.25, 0.13))
