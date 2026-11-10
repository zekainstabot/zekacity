extends Node2D

# Decorative isometric city silhouette for the ZekaCity loading screen.

func _draw():
	var viewport_size = get_viewport_rect().size
	var horizon = viewport_size.y * 0.78
	var colors = [
		Color(0.045, 0.12, 0.19, 0.9),
		Color(0.055, 0.16, 0.22, 0.9),
		Color(0.065, 0.19, 0.25, 0.9)
	]

	# Build a skyline that adapts to wide and narrow desktop windows.
	var x = -35.0
	var index = 0

	while x < viewport_size.x + 40.0:
		var width = 54.0 + float((index % 3) * 12)
		var height = 78.0 + float((index * 47) % 135)
		var rect = Rect2(
			Vector2(x, horizon - height),
			Vector2(width, height)
		)

		draw_rect(rect, colors[index % colors.size()])

		# Small windows add a warm, lived-in city feel.
		for window_x in range(int(x + 11), int(x + width - 7), 17):
			for window_y in range(int(rect.position.y + 14), int(horizon - 9), 23):
				draw_rect(
					Rect2(Vector2(window_x, window_y), Vector2(4, 7)),
					Color(0.18, 0.62, 0.63, 0.34)
				)

		x += width + 12.0
		index += 1

	# Soft isometric grid along the bottom edge.
	for line_x in range(
		int(-viewport_size.y),
		int(viewport_size.x + viewport_size.y),
		48
	):
		draw_line(
			Vector2(line_x, horizon),
			Vector2(line_x + viewport_size.y * 0.5, viewport_size.y),
			Color(0.16, 0.58, 0.61, 0.12),
			1.0
		)

	for line_y in range(int(horizon), int(viewport_size.y + 40), 32):
		draw_line(
			Vector2(0, line_y),
			Vector2(viewport_size.x, line_y),
			Color(0.16, 0.58, 0.61, 0.10),
			1.0
		)
