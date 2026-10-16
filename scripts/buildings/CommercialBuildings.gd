extends Reference

# =========================================
# ZekaCity - CommercialBuildings.gd
# Godot 3.6
# رسم ساختمان‌های تجاری و صنعتی
# =========================================


func draw_building(canvas, building_id, pos):
	match building_id:
		"grocery_store":
			_draw_shop(canvas, pos, Color(0.25, 0.75, 0.45))

		"bakery":
			_draw_shop(canvas, pos, Color(0.85, 0.57, 0.28))

		"restaurant":
			_draw_shop(canvas, pos, Color(0.85, 0.32, 0.25))

		"office":
			_draw_office(canvas, pos, 1)

		"shopping_mall":
			_draw_office(canvas, pos, 2)

		"factory":
			_draw_factory(canvas, pos)


# =========================================
# SHOPS AND RESTAURANTS
# =========================================

func _draw_shop(canvas, pos, shop_color):
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-34, 0),
			pos + Vector2(0, 16),
			pos + Vector2(0, -25),
			pos + Vector2(-34, -41)
		]),
		Color(0.80, 0.77, 0.69)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 16),
			pos + Vector2(34, 0),
			pos + Vector2(34, -41),
			pos + Vector2(0, -25)
		]),
		Color(0.91, 0.87, 0.77)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-39, -41),
			pos + Vector2(0, -58),
			pos + Vector2(39, -41),
			pos + Vector2(0, -24)
		]),
		shop_color
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(-8, -18), Vector2(12, 22)),
		Color(0.35, 0.23, 0.16)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(10, -32), Vector2(12, 10)),
		Color(0.55, 0.83, 0.98)
	)


# =========================================
# OFFICES AND MALLS
# =========================================

func _draw_office(canvas, pos, level):
	var height = 70 if level == 1 else 95
	var width = 48 if level == 1 else 65

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-width / 2, 0),
			pos + Vector2(0, 20),
			pos + Vector2(0, 20 - height),
			pos + Vector2(-width / 2, -height)
		]),
		Color(0.27, 0.42, 0.54)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 20),
			pos + Vector2(width / 2, 0),
			pos + Vector2(width / 2, -height),
			pos + Vector2(0, 20 - height)
		]),
		Color(0.43, 0.64, 0.76)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-width / 2, -height),
			pos + Vector2(0, -height - 18),
			pos + Vector2(width / 2, -height),
			pos + Vector2(0, 20 - height)
		]),
		Color(0.22, 0.31, 0.39)
	)

	for floor_index in range(4):
		var wy = -height + 12 + floor_index * 14

		canvas.draw_rect(
			Rect2(
				pos + Vector2(-width / 2 + 7, wy),
				Vector2(8, 9)
			),
			Color(0.62, 0.86, 0.98)
		)

		canvas.draw_rect(
			Rect2(
				pos + Vector2(8, wy),
				Vector2(8, 9)
			),
			Color(0.62, 0.86, 0.98)
		)

		canvas.draw_rect(
			Rect2(
				pos + Vector2(21, wy),
				Vector2(8, 9)
			),
			Color(0.62, 0.86, 0.98)
		)


# =========================================
# FACTORY
# =========================================

func _draw_factory(canvas, pos):
	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-38, 0),
			pos + Vector2(0, 18),
			pos + Vector2(0, -30),
			pos + Vector2(-38, -48)
		]),
		Color(0.48, 0.50, 0.51)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(0, 18),
			pos + Vector2(38, 0),
			pos + Vector2(38, -48),
			pos + Vector2(0, -30)
		]),
		Color(0.63, 0.65, 0.64)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([
			pos + Vector2(-38, -48),
			pos + Vector2(-10, -64),
			pos + Vector2(20, -48),
			pos + Vector2(0, -30)
		]),
		Color(0.38, 0.40, 0.42)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(15, -73), Vector2(10, 40)),
		Color(0.50, 0.32, 0.27)
	)

	canvas.draw_rect(
		Rect2(pos + Vector2(-24, -24), Vector2(12, 12)),
		Color(0.85, 0.83, 0.62)
	)
