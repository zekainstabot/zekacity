extends Reference


func draw_building(canvas, building_id, pos):
	match building_id:
		"school":
			_draw_public_building(
				canvas,
				pos,
				Color(0.90, 0.76, 0.30)
			)

		"university":
			_draw_university(canvas, pos)


func _draw_public_building(canvas, pos, main_color):
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-35, 0),
			pos + Vector2(0, 18),
			pos + Vector2(0, -37),
			pos + Vector2(-35, -55)
		]),
		main_color.darkened(0.25)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 18),
			pos + Vector2(35, 0),
			pos + Vector2(35, -55),
			pos + Vector2(0, -37)
		]),
		main_color
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-40, -55),
			pos + Vector2(0, -76),
			pos + Vector2(40, -55),
			pos + Vector2(0, -34)
		]),
		main_color.darkened(0.12)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(-7, -20), Vector2(14, 26)),
		Color(0.30, 0.23, 0.18)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(-26, -43), Vector2(10, 10)),
		Color(0.65, 0.85, 0.98)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(12, -43), Vector2(10, 10)),
		Color(0.65, 0.85, 0.98)
	)


func _draw_university(canvas, pos):
	_draw_public_building(
		canvas,
		pos,
		Color(0.77, 0.67, 0.42)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-42, -56),
			pos + Vector2(0, -83),
			pos + Vector2(42, -56),
			pos + Vector2(0, -34)
		]),
		Color(0.49, 0.29, 0.19)
	)

	canvas.draw_line(
		pos + Vector2(0, -82),
		pos + Vector2(0, -98),
		Color(0.48, 0.35, 0.22),
		3
	)
