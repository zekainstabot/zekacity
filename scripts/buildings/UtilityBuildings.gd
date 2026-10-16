extends Reference


func draw_building(canvas, building_id, pos):
	match building_id:
		"water_tower":
			_draw_water_tower(canvas, pos)
		"power_station":
			_draw_power_station(canvas, pos)
		"sewage_plant":
			_draw_utility_plant(canvas, pos, Color(0.43, 0.52, 0.36))
		"waste_facility":
			_draw_utility_plant(canvas, pos, Color(0.50, 0.44, 0.34))


func _draw_water_tower(canvas, pos):
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-25, -45),
			pos + Vector2(0, -58),
			pos + Vector2(25, -45),
			pos + Vector2(0, -32)
		]),
		Color(0.30, 0.63, 0.85)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(-25, -45), Vector2(50, 20)),
		Color(0.30, 0.63, 0.85)
	)

	canvas.draw_line(
		pos + Vector2(-18, -25),
		pos + Vector2(-27, 8),
		Color(0.48, 0.49, 0.50),
		4
	)

	canvas.draw_line(
		pos + Vector2(18, -25),
		pos + Vector2(27, 8),
		Color(0.48, 0.49, 0.50),
		4
	)

	canvas.draw_line(
		pos + Vector2(-23, -2),
		pos + Vector2(23, -2),
		Color(0.48, 0.49, 0.50),
		3
	)


func _draw_power_station(canvas, pos):
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-35, 0),
			pos + Vector2(0, 16),
			pos + Vector2(0, -25),
			pos + Vector2(-35, -41)
		]),
		Color(0.67, 0.61, 0.48)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 16),
			pos + Vector2(35, 0),
			pos + Vector2(35, -41),
			pos + Vector2(0, -25)
		]),
		Color(0.78, 0.73, 0.60)
	)

	canvas.draw_line(
		pos + Vector2(-15, -47),
		pos + Vector2(-15, -75),
		Color(0.40, 0.42, 0.43),
		3
	)

	canvas.draw_line(
		pos + Vector2(15, -47),
		pos + Vector2(15, -75),
		Color(0.40, 0.42, 0.43),
		3
	)

	canvas.draw_line(
		pos + Vector2(-28, -65),
		pos + Vector2(28, -65),
		Color(0.40, 0.42, 0.43),
		3
	)

	canvas.draw_line(
		pos + Vector2(-24, -56),
		pos + Vector2(24, -56),
		Color(0.40, 0.42, 0.43),
		2
	)


func _draw_utility_plant(canvas, pos, plant_color):
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-32, 0),
			pos + Vector2(0, 16),
			pos + Vector2(0, -28),
			pos + Vector2(-32, -44)
		]),
		plant_color.darkened(0.2)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 16),
			pos + Vector2(32, 0),
			pos + Vector2(32, -44),
			pos + Vector2(0, -28)
		]),
		plant_color
	)

	canvas.draw_circle(
		pos + Vector2(0, -48),
		14,
		Color(0.62, 0.72, 0.76)
	)

	canvas.draw_arc(
		pos + Vector2(0, -48),
		14,
		0,
		PI * 2,
		24,
		Color(0.35, 0.42, 0.45),
		2
	)
