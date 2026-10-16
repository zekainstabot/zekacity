
extends Reference

# ZekaCity - LandSelection.gd
# Godot 3.6
# تبدیل کلیک ماوس به مختصات لوزی شبکه

func get_selected_tile(mouse_pos, center, grid_size, tile_width, tile_height):
	var best_tile = Vector2(-1, -1)
	var best_distance = INF

	for x in range(grid_size):
		for y in range(grid_size):
			var tile_pos = center + Vector2(
				(x - y) * tile_width / 2.0,
				(x + y) * tile_height / 2.0
			)

			var local_pos = mouse_pos - tile_pos

			var inside_tile = (
				abs(local_pos.x) / (tile_width / 2.0)
				+ abs(local_pos.y) / (tile_height / 2.0)
			) <= 1.0

			if inside_tile:
				var distance = local_pos.length()

				if distance < best_distance:
					best_distance = distance
					best_tile = Vector2(x, y)

	return best_tile
