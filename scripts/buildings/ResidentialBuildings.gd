extends Reference

# =========================================
# ZekaCity - ResidentialBuildings.gd
# Godot 3.6
# =========================================

func draw_building(canvas, building_id, pos):
	var scale_factor = 1.0

	match building_id:
		"small_house":
			scale_factor = 1.0
		"normal_house":
			scale_factor = 1.4
		"low_apartment":
			scale_factor = 1.7
		"high_apartment":
			scale_factor = 2.0
		"residential_tower":
			scale_factor = 2.3
		_:
			return

	canvas.draw_set_transform(
		pos,
		0.0,
		Vector2(scale_factor, scale_factor)
	)

	match building_id:
		"small_house":
			_draw_house(canvas, Vector2.ZERO, 0)
		"normal_house":
			_draw_house(canvas, Vector2.ZERO, 1)
		"low_apartment":
			_draw_apartment(canvas, Vector2.ZERO, 1)
		"high_apartment":
			_draw_apartment(canvas, Vector2.ZERO, 2)
		"residential_tower":
			_draw_apartment(canvas, Vector2.ZERO, 3)

	canvas.draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)


# =========================================
# HOUSE DESIGNS
# =========================================

func _draw_house(canvas, pos, style):
	var wall_color = Color(0.88, 0.72, 0.50)
	var roof_color = Color(0.65, 0.22, 0.18)
	var height = 38

	if style == 1:
		wall_color = Color(0.82, 0.83, 0.78)
		roof_color = Color(0.25, 0.38, 0.60)
		height = 48

	# سمت چپ خانه
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-32, -4),
			pos + Vector2(0, 12),
			pos + Vector2(0, 12 - height),
			pos + Vector2(-32, -height - 4)
		]),
		wall_color.darkened(0.18)
	)

	# سمت راست خانه
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 12),
			pos + Vector2(32, -4),
			pos + Vector2(32, -height - 4),
			pos + Vector2(0, 12 - height)
		]),
		wall_color
	)

	# سقف
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-38, -height - 4),
			pos + Vector2(0, -height - 24),
			pos + Vector2(38, -height - 4),
			pos + Vector2(0, -height + 14)
		]),
		roof_color
	)

	# در
	canvas.draw_rect(
		Rect2(pos + Vector2(-7, -20), Vector2(12, 24)),
		Color(0.30, 0.19, 0.12)
	)

	# پنجره‌ها
	canvas.draw_rect(
		Rect2(pos + Vector2(-25, -height + 5), Vector2(12, 12)),
		Color(0.55, 0.82, 0.95)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(12, -height + 5), Vector2(12, 12)),
		Color(0.55, 0.82, 0.95)
	)


# =========================================
# APARTMENT BUILDINGS
# =========================================

func _draw_apartment(canvas, pos, level):
	var height = 45 + level * 20
	var width = 48 + level * 4
	var half_width = float(width) / 2.0
	var wall = Color(0.72, 0.76, 0.81)

	# نمای چپ
	var left_face = PoolVector2Array([
		pos + Vector2(-half_width, 0),
		pos + Vector2(0, 18),
		pos + Vector2(0, 18 - height),
		pos + Vector2(-half_width, -height + 2)
	])

	canvas.draw_colored_polygon(
		left_face,
		wall.darkened(0.25)
	)

	# نمای راست
	var right_face = PoolVector2Array([
		pos + Vector2(0, 18),
		pos + Vector2(half_width, 0),
		pos + Vector2(half_width, -height),
		pos + Vector2(0, 18 - height)
	])

	canvas.draw_colored_polygon(
		right_face,
		wall
	)

	# سقف
	var roof = PoolVector2Array([
		pos + Vector2(-half_width, -height + 2),
		pos + Vector2(0, -height - 10),
		pos + Vector2(half_width, -height),
		pos + Vector2(0, 18 - height)
	])

	canvas.draw_colored_polygon(
		roof,
		Color(0.35, 0.40, 0.48)
	)

	# پنجره‌های طبقات
	for floor_index in range(level + 2):
		var wy = 8 - floor_index * 15

		canvas.draw_rect(
			Rect2(
				pos + Vector2(-half_width + 7, wy - 10),
				Vector2(8, 8)
			),
			Color(0.55, 0.83, 0.98)
		)

		canvas.draw_rect(
			Rect2(
				pos + Vector2(-half_width + 22, wy - 10),
				Vector2(8, 8)
			),
			Color(0.55, 0.83, 0.98)
		)

		canvas.draw_rect(
			Rect2(
				pos + Vector2(8, wy - 10),
				Vector2(8, 8)
			),
			Color(0.55, 0.83, 0.98)
		)

		canvas.draw_rect(
			Rect2(
				pos + Vector2(23, wy - 10),
				Vector2(8, 8)
			),
			Color(0.55, 0.83, 0.98)
		)
