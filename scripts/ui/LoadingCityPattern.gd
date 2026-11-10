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

	# Distant skyline.
	var buildings = [
		Rect2(Vector2(25, horizon - 105), Vector2(65, 105)),
		Rect2(Vector2(105, horizon - 155), Vector2(82, 155)),
		Rect2(Vector2(205, horizon - 85), Vector2(58, 85)),
		Rect2(Vector2(285, horizon - 190), Vector2(90, 190)),
		Rect2(Vector2(390, horizon - 125), Vector2(72, 125)),
		Rect2(Vector2(490, horizon - 165), Vector2(86, 165)),
		Rect2(Vector2(600, horizon - 95), Vector2(66, 95)),
		Rect2(Vector2(690, horizon - 210), Vector2(94, 210)),
		Rect2(Vector2(810, horizon - 120), Vector2(70, 120)),
		Rect2(Vector2(900, horizon - 175), Vector2(88, 175)),
		Rect2(Vector2(1010, horizon - 100), Vector2(65, 100)),
		Rect2(Vector2(1090, horizon - 145), Vector2(82, 145))
	]

	for i in range(buildings.size()):
		var rect = buildings[i]
		draw_rect(rect, colors[i % colors.size()])

		# Small glowing windows.
		for x in range(int(rect.position.x + 12), int(rect.position.x + rect.size.x - 8), 18):
			for y in range(int(rect.position.y + 14), int(horizon - 10), 24):
				draw_rect(
					Rect2(Vector2(x, y), Vector2(4, 7)),
					Color(0.18, 0.62, 0.63, 0.34)
				)

	# Soft isometric grid along the bottom edge.
	for x in range(-viewport_size.y, viewport_size.x + viewport_size.y, 48):
		draw_line(
			Vector2(x, horizon),
			Vector2(x + viewport_size.y * 0.5, viewport_size.y),
			Color(0.16, 0.58, 0.61, 0.12),
			1.0
		)

	for y in range(int(horizon), int(viewport_size.y + 40), 32):
		draw_line(
			Vector2(0, y),
			Vector2(viewport_size.x, y),
			Color(0.16, 0.58, 0.61, 0.10),
			1.0
		)
