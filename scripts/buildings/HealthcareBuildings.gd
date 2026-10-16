extends Reference


func draw_building(canvas, building_id, pos):
	match building_id:
		"clinic":
			_draw_clinic(canvas, pos, false)

		"hospital":
			_draw_clinic(canvas, pos, true)


func _draw_clinic(canvas, pos, is_hospital):
	var building_color = Color(0.85, 0.88, 0.87)
	var building_height = 50

	if is_hospital:
		building_color = Color(0.78, 0.85, 0.89)
		building_height = 75

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-35, 0),
			pos + Vector2(0, 17),
			pos + Vector2(0, -building_height),
			pos + Vector2(-35, -building_height - 17)
		]),
		building_color.darkened(0.2)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 17),
			pos + Vector2(35, 0),
			pos + Vector2(35, -building_height - 17),
			pos + Vector2(0, -building_height)
		]),
		building_color
	)

	canvas.draw_rect(
		Rect2(
			pos + Vector2(-7, -building_height + 8),
			Vector2(14, 28)
		),
		Color(0.85, 0.20, 0.20)
	)

	canvas.draw_rect(
		Rect2(
			pos + Vector2(-14, -building_height + 15),
			Vector2(28, 14)
		),
		Color(0.85, 0.20, 0.20)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(-8, -19), Vector2(14, 22)),
		Color(0.35, 0.44, 0.49)
	)
