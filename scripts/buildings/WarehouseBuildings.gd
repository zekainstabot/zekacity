
extends Reference

# ZekaCity - WarehouseBuildings.gd
# Godot 3.6

static func draw_building(canvas, building_id, pos):
	var footprint = _get_footprint(building_id)
	var width = footprint.x
	var depth = footprint.y

	var tile_width = 64.0
	var tile_height = 32.0
	var height = 28.0

	match building_id:
		"medium_warehouse":
			height = 38.0
		"large_warehouse":
			height = 48.0
		"huge_warehouse":
			height = 58.0

	# pos مرکز footprint است؛ نه گوشه جلویی ساختمان
	var half_x = tile_width * (width + depth) / 4.0
	var half_y = tile_height * (width + depth) / 4.0

	var top = pos + Vector2(
		(tile_width / 4.0) * (depth - width),
		-half_y
	)

	var right = pos + Vector2(
		half_x,
		(tile_height / 4.0) * (width - depth)
	)

	var bottom = pos + Vector2(
		(tile_width / 4.0) * (depth - width),
		half_y
	)

	var left = pos + Vector2(
		-half_x,
		(tile_height / 4.0) * (depth - width)
	)

	var roof_top = top - Vector2(0, height)
	var roof_right = right - Vector2(0, height)
	var roof_bottom = bottom - Vector2(0, height)
	var roof_left = left - Vector2(0, height)

	var outline = Color(0.16, 0.18, 0.20)

	# دیوار سمت چپ
	canvas.draw_colored_polygon(
		PoolVector2Array([
			roof_left, roof_bottom, bottom, left
		]),
		Color(0.58, 0.44, 0.29)
	)

	# دیوار سمت راست
	canvas.draw_colored_polygon(
		PoolVector2Array([
			roof_bottom, roof_right, right, bottom
		]),
		Color(0.40, 0.30, 0.21)
	)

	# سقف
	canvas.draw_colored_polygon(
		PoolVector2Array([
			roof_top, roof_left, roof_bottom, roof_right
		]),
		Color(0.32, 0.38, 0.42)
	)

	# خطوط سقف و دیوارها
	canvas.draw_line(roof_top, roof_left, outline, 2.0)
	canvas.draw_line(roof_left, roof_bottom, outline, 2.0)
	canvas.draw_line(roof_bottom, roof_right, outline, 2.0)
	canvas.draw_line(roof_right, roof_top, outline, 2.0)
	canvas.draw_line(roof_left, left, outline, 2.0)
	canvas.draw_line(roof_right, right, outline, 2.0)
	canvas.draw_line(roof_bottom, bottom, outline, 2.0)

	# در ورودی روی دیوار جلویی
	var door_width = 12.0 + max(width, depth) * 2.0
	var door_height = 16.0 + max(width, depth) * 2.0
	var door_top = roof_bottom + Vector2(0, door_height * 0.15)

	var door = PoolVector2Array([
		door_top + Vector2(-door_width / 2.0, 0),
		door_top + Vector2(door_width / 2.0, 0),
		bottom + Vector2(0, -2.0),
		door_top + Vector2(-door_width / 2.0, 0)
	])

	canvas.draw_colored_polygon(
		door,
		Color(0.20, 0.15, 0.11)
	)


static func _get_footprint(building_id):
	match building_id:
		"small_warehouse":
			return Vector2(2, 2)
		"medium_warehouse":
			return Vector2(3, 2)
		"large_warehouse":
			return Vector2(3, 3)
		"huge_warehouse":
			return Vector2(4, 3)

	return Vector2(2, 2)
