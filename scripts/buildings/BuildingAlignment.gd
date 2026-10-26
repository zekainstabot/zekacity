extends Reference

# ZekaCity - BuildingAlignment.gd
# Isometric building alignment helper for Godot 3.6

const DEFAULT_TILE_WIDTH = 64.0
const DEFAULT_TILE_HEIGHT = 32.0
const BUILDING_HEIGHT_MULTIPLIER = 1.5
const MIN_TARGET_HEIGHT = 64.0


func get_visual_grid_position(grid_pos, footprint):
	var safe_footprint = Vector2(
		max(1.0, footprint.x),
		max(1.0, footprint.y)
	)

	return grid_pos + Vector2(
		(safe_footprint.x - 1.0) / 2.0,
		(safe_footprint.y - 1.0) / 2.0
	)


func get_ground_footprint_size(footprint,
		tile_width = DEFAULT_TILE_WIDTH,
		tile_height = DEFAULT_TILE_HEIGHT):
	var safe_footprint = Vector2(
		max(1.0, footprint.x),
		max(1.0, footprint.y)
	)

	return Vector2(
		(safe_footprint.x + safe_footprint.y) * tile_width / 2.0,
		(safe_footprint.x + safe_footprint.y) * tile_height / 2.0
	)


func get_target_size(footprint,
		tile_width = DEFAULT_TILE_WIDTH,
		tile_height = DEFAULT_TILE_HEIGHT):
	var ground_size = get_ground_footprint_size(
		footprint,
		tile_width,
		tile_height
	)

	return Vector2(
		max(tile_width, ground_size.x),
		max(
			MIN_TARGET_HEIGHT,
			ground_size.y * BUILDING_HEIGHT_MULTIPLIER
		)
	)
