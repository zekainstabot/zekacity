extends Reference


func draw_building(canvas, building_id, pos):
	match building_id:
		"small_park":
			_draw_park(canvas, pos, false)

		"playground":
			_draw_playground(canvas, pos)

		"sports_center":
			_draw_sports_center(canvas, pos)

		"cultural_center":
			_draw_cultural_center(canvas, pos)


func _draw_park(canvas, pos, include_fountain):
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-48, 0),
			pos + Vector2(0, 24),
			pos + Vector2(48, 0),
			pos + Vector2(0, -24)
		]),
		Color(0.25, 0.62, 0.29)
	)

	_draw_tree(canvas, pos + Vector2(-20, -7))
	_draw_tree(canvas, pos + Vector2(18, -8))
	_draw_tree(canvas, pos + Vector2(0, 8))

	canvas.draw_line(
		pos + Vector2(-25, 5),
		pos + Vector2(25, -7),
		Color(0.80, 0.72, 0.48),
		4
	)

	if include_fountain:
		canvas.draw_circle(
			pos + Vector2(0, -2),
			9,
			Color(0.25, 0.75, 0.94)
		)


func _draw_tree(canvas, pos):
	canvas.draw_rect(
		Rect2(pos + Vector2(-3, 0), Vector2(6, 14)),
		Color(0.38, 0.23, 0.12)
	)

	canvas.draw_circle(
		pos + Vector2(0, -5),
		13,
		Color(0.12, 0.43, 0.17)
	)

	canvas.draw_circle(
		pos + Vector2(-6, -10),
		8,
		Color(0.19, 0.55, 0.22)
	)

	canvas.draw_circle(
		pos + Vector2(7, -11),
		8,
		Color(0.22, 0.60, 0.25)
	)


func _draw_playground(canvas, pos):
	_draw_park(canvas, pos, false)

	canvas.draw_line(
		pos + Vector2(-15, -5),
		pos + Vector2(-15, -28),
		Color(0.92, 0.25, 0.20),
		4
	)

	canvas.draw_line(
		pos + Vector2(-15, -28),
		pos + Vector2(12, -28),
		Color(0.92, 0.25, 0.20),
		4
	)

	canvas.draw_line(
		pos + Vector2(12, -28),
		pos + Vector2(12, -5),
		Color(0.92, 0.25, 0.20),
		4
	)

	canvas.draw_line(
		pos + Vector2(18, -5),
		pos + Vector2(30, 5),
		Color(0.25, 0.40, 0.85),
		4
	)


func _draw_sports_center(canvas, pos):
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-40, 0),
			pos + Vector2(0, 20),
			pos + Vector2(0, -45),
			pos + Vector2(-40, -65)
		]),
		Color(0.28, 0.52, 0.72)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 20),
			pos + Vector2(40, 0),
			pos + Vector2(40, -65),
			pos + Vector2(0, -45)
		]),
		Color(0.38, 0.65, 0.83)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-45, -65),
			pos + Vector2(0, -86),
			pos + Vector2(45, -65),
			pos + Vector2(0, -44)
		]),
		Color(0.25, 0.38, 0.48)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(-18, -36), Vector2(36, 18)),
		Color(0.72, 0.88, 0.95)
	)


func _draw_cultural_center(canvas, pos):
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-40, 0),
			pos + Vector2(0, 20),
			pos + Vector2(0, -40),
			pos + Vector2(-40, -60)
		]),
		Color(0.69, 0.46, 0.65)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 20),
			pos + Vector2(40, 0),
			pos + Vector2(40, -60),
			pos + Vector2(0, -40)
		]),
		Color(0.82, 0.59, 0.76)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-45, -60),
			pos + Vector2(0, -82),
			pos + Vector2(45, -60),
			pos + Vector2(0, -38)
		]),
		Color(0.47, 0.30, 0.47)
	)

	canvas.draw_circle(
		pos + Vector2(0, -22),
		12,
		Color(0.95, 0.83, 0.55)
	)
