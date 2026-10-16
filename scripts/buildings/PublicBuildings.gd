extends Reference

func draw_building(canvas, building_id, pos):
	match building_id:
		"school":
			_draw_public_building(
				canvas,
				pos,
				Color(0.90, 0.76, 0.30)
			)

		"police_station":
			_draw_public_building(
				canvas,
				pos,
				Color(0.35, 0.55, 0.85)
			)

		"fire_station":
			_draw_public_building(
				canvas,
				pos,
				Color(0.85, 0.25, 0.20)
			)

		"city_hall":
			_draw_city_hall(canvas, pos)


func _draw_public_building(canvas, pos, main_color):
	var base = PoolVector2Array([
		pos + Vector2(-28, -18),
		pos + Vector2(0, -32),
		pos + Vector2(28, -18),
		pos + Vector2(0, -4)
	])

	canvas.draw_colored_polygon(
		base,
		Color(0.45, 0.45, 0.45)
	)

	canvas.draw_rect(
		Rect2(pos.x - 20, pos.y - 48, 40, 30),
		main_color
	)

	canvas.draw_rect(
		Rect2(pos.x - 24, pos.y - 52, 48, 5),
		Color(0.35, 0.35, 0.35)
	)

	canvas.draw_rect(
		Rect2(pos.x - 5, pos.y - 28, 10, 10),
		Color(0.25, 0.25, 0.25)
	)

	canvas.draw_rect(
		Rect2(pos.x - 16, pos.y - 42, 7, 7),
		Color(0.75, 0.90, 1.0)
	)

	canvas.draw_rect(
		Rect2(pos.x + 9, pos.y - 42, 7, 7),
		Color(0.75, 0.90, 1.0)
	)


func _draw_city_hall(canvas, pos):
	_draw_public_building(
		canvas,
		pos,
		Color(0.82, 0.82, 0.75)
	)

	canvas.draw_rect(
		Rect2(pos.x - 4, pos.y - 62, 8, 10),
		Color(0.75, 0.65, 0.35)
	)
