extends Node2D

const GROUND_OFFSET_Y = 0.0
const SMALL_HOUSE_OFFSET_Y = 0.0

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
		position = world.grid_to_screen(
			visual_grid_pos,
			Vector2(600, 130)
		)

		z_index = int(round(
			visual_grid_pos.x + visual_grid_pos.y
		))

	update()


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

		var target_size = Vector2(
			max(64.0, (footprint.x + footprint.y) * 32.0),
			max(64.0, (footprint.x + footprint.y) * 24.0)
		)

		var scale_factor = min(
			target_size.x / texture_size.x,
			target_size.y / texture_size.y
		)

		var anchor_x = texture_size.x / 2.0
		var anchor_y = texture_size.y

		if has_visible_bounds:
			anchor_x = (
				visible_bounds.position.x
				+ visible_bounds.size.x / 2.0
			)
			anchor_y = visible_bounds.end.y

		var extra_offset_y = 0.0

		if building_id == "small_house":
			extra_offset_y = SMALL_HOUSE_OFFSET_Y

		var draw_position = Vector2(
			-anchor_x * scale_factor,
			-anchor_y * scale_factor
			+ GROUND_OFFSET_Y
			+ extra_offset_y
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

		return

	if drawer != null:
		drawer.draw_building(
			self,
			building_id,
			Vector2.ZERO
		)
