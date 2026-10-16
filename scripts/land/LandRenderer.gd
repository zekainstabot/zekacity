
extends Reference

# ZekaCity - LandRenderer.gd
# Godot 3.6
# رسم شبکه کوچک زمین و مشخص کردن مالکیت

var tile_width = 64
var tile_height = 32

var owned_color = Color(0.36, 0.56, 0.34)
var available_color = Color(0.68, 0.65, 0.43)

var owned_outline = Color(0.20, 0.35, 0.20)
var available_outline = Color(0.83, 0.75, 0.35)
var selected_outline = Color(1.0, 0.85, 0.1)


func get_tile_width():
	return tile_width


func get_tile_height():
	return tile_height


func grid_to_screen(grid_pos, center):
	return center + Vector2(
		(grid_pos.x - grid_pos.y) * tile_width / 2.0,
		(grid_pos.x + grid_pos.y) * tile_height / 2.0
	)


func get_tile_polygon(pos):
	return PoolVector2Array([
		pos + Vector2(0, -tile_height / 2.0),
		pos + Vector2(tile_width / 2.0, 0),
		pos + Vector2(0, tile_height / 2.0),
		pos + Vector2(-tile_width / 2.0, 0)
	])


func draw_tiles(canvas, land_system, grid_size, center, selected_x, selected_y):
	for x in range(grid_size):
		for y in range(grid_size):
			var grid_pos = Vector2(x, y)
			var tile_pos = grid_to_screen(grid_pos, center)
			var polygon = get_tile_polygon(tile_pos)

			var fill_color = available_color
			var outline_color = available_outline

			if land_system.is_owned(grid_pos):
				fill_color = owned_color
				outline_color = owned_outline

			if x == selected_x and y == selected_y:
				outline_color = selected_outline

			canvas.draw_colored_polygon(polygon, fill_color)

			canvas.draw_polyline(
				PoolVector2Array([
					polygon[0],
					polygon[1],
					polygon[2],
					polygon[3],
					polygon[0]
				]),
				outline_color,
				1.0
			)
