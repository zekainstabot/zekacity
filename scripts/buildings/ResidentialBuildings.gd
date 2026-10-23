extends Reference

# =========================================
# ZekaCity - ResidentialBuildings.gd
# Godot 3.6
# =========================================

const TILE_HALF_WIDTH = 32.0
const TILE_HALF_HEIGHT = 16.0


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
	var height = 38.0

	if style == 1:
		wall_color = Color(0.82, 0.83, 0.78)
		roof_color = Color(0.25, 0.38, 0.60)
		height = 48.0

	# گوشه‌های پایهٔ لوزی:
	# عقب: (0, -16)
	# راست: (32, 0)
	# جلو: (0, 16)
	# چپ: (-32, 0)

	var back = pos + Vector2(0, -16)
	var right = pos + Vector2(32, 0)
	var front = pos + Vector2(0, 16)
	var left = pos + Vector2(-32, 0)

	var back_top = back + Vector2(0, -height)
	var right_top = right + Vector2(0, -height)
	var front_top = front + Vector2(0, -height)
	var left_top = left + Vector2(0, -height)

	# دیوار چپ: از گوشهٔ چپ تا عقب و بالای آن‌ها
	canvas.draw_colored_polygon(
		PoolVector2Array([
			left,
			front,
			front_top,
			left_top
		]),
		wall_color.darkened(0.18)
	)

	# دیوار راست: از جلو تا راست و بالای آن‌ها
	canvas.draw_colored_polygon(
		PoolVector2Array([
			front,
			right,
			right_top,
			front_top
		]),
		wall_color
	)

	# سقف: لبه‌ها دقیقاً با گوشه‌های بالای دیوار هماهنگ‌اند
	canvas.draw_colored_polygon(
		PoolVector2Array([
			left_top,
			back_top,
			right_top,
			front_top
		]),
		roof_color
	)

	# در روی نمای جلویی
	canvas.draw_rect(
		Rect2(
			pos + Vector2(-6, -16),
			Vector2(12, 24)
		),
		Color(0.30, 0.19, 0.12)
	)

	# پنجره‌های دیوار چپ
	canvas.draw_rect(
		Rect2(
			pos + Vector2(-25, -height + 4),
			Vector2(10, 10)
		),
		Color(0.55, 0.82, 0.95)
	)

	# پنجرهٔ دیوار راست
	canvas.draw_rect(
		Rect2(
			pos + Vector2(12, -height + 4),
			Vector2(10, 10)
		),
		Color(0.55, 0.82, 0.95)
	)


# =========================================
# APARTMENT BUILDINGS
# =========================================

func _draw_apartment(canvas, pos, level):
	var height = 45.0 + level * 20.0
	var width = 48.0 + level * 4.0
	var half_width = width / 2.0
	var wall = Color(0.72, 0.76, 0.81)

	# گوشه‌های پایهٔ ساختمان
	var back = pos + Vector2(0, -16)
	var right = pos + Vector2(half_width, 0)
	var front = pos + Vector2(0, 16)
	var left = pos + Vector2(-half_width, 0)

	# گوشه‌های بالای دیوارها
	var back_top = back + Vector2(0, -height)
	var right_top = right + Vector2(0, -height)
	var front_top = front + Vector2(0, -height)
	var left_top = left + Vector2(0, -height)

	# نمای چپ
	var left_face = PoolVector2Array([
		left,
		front,
		front_top,
		left_top
	])

	canvas.draw_colored_polygon(
		left_face,
		wall.darkened(0.25)
	)

	# نمای راست
	var right_face = PoolVector2Array([
		front,
		right,
		right_top,
		front_top
	])

	canvas.draw_colored_polygon(
		right_face,
		wall
	)

	# سقف
	var roof = PoolVector2Array([
		left_top,
		back_top,
		right_top,
		front_top
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
