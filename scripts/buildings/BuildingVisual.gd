
extends Node2D

const GROUND_OFFSET_Y = 0.0
const BUILDING_SCALE_MULTIPLIER = 1.2

var world = null
var building_id = ""
var grid_pos = Vector2.ZERO
var building_texture = null
var drawer = null

var has_visible_bounds = false
var visible_bounds = Rect2()


func setup(p_world, p_building_id, p_grid_pos):
	world = p_world
	building_id = p_building_id
	grid_pos = p_grid_pos

	var texture_paths = {
		"small_house": "res://BuildingImages/small_house.png",
		"normal_house": "res://BuildingImages/normal_house.png",
		"low_apartment": "res://BuildingImages/low_apartment.png",
		"high_apartment": "res://BuildingImages/high_apartment.png",
		"residential_tower": "res://BuildingImages/residential_tower.png",
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

	if texture_paths.has(building_id):
		var texture_path = texture_paths[building_id]

		if ResourceLoader.exists(texture_path):
			building_texture = load(texture_path)
		else:
			push_warning("Building texture not found: " + texture_path)

	if building_texture != null:
		_calculate_visible_bounds()
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

	if building_texture != null:
		var texture_size = building_texture.get_size()

		if texture_size.x <= 0 or texture_size.y <= 0:
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

		var scale_factor = min(
			target_size.x / texture_size.x,
			target_size.y / texture_size.y
		) * BUILDING_SCALE_MULTIPLIER

		var anchor_x = texture_size.x / 2.0
		var anchor_y = texture_size.y

		if has_visible_bounds:
			anchor_x = (
				visible_bounds.position.x
				+ visible_bounds.size.x / 2.0
			)

			anchor_y = visible_bounds.end.y

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
		if building_id in [
			"small_house",
			"normal_house",
			"low_apartment",
			"high_apartment",
			"residential_tower"
		]:
			if not world._building_has_road_access(
				building_id,
				grid_pos
			):
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

		return

	if drawer != null:
		drawer.draw_building(
			self,
			building_id,
			Vector2.ZERO
		)
func refresh_road_warning():
	update()
