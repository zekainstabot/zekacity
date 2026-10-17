
extends Reference

# ZekaCity - WarehouseBuildings.gd
# Godot 3.6

static func draw_building(canvas, building_id, pos):
	var footprint = _get_footprint(building_id)
	var width = footprint.x
	var depth = footprint.y

	var tile_width = 64.0
	var tile_height = 32.0

	var half_w = tile_width * width / 2.0
	var half_d = tile_width * depth / 2.0
	var ground_h = tile_height * (width + depth) / 2.0

	var height = 28.0

	match building_id:
		"medium_warehouse":
			height = 38.0
		"large_warehouse":
			height = 48.0
		"huge_warehouse":
			height = 58.0

	# pos نقطه مرکزی لبه جلویی ساختمان است.
	var front = pos
	var left = Vector2(pos.x - half_w, pos.y - tile_height * width / 2.0)
	var right = Vector2(pos.x + half_d, pos.y - tile_height * depth / 2.0)
	var back = Vector2(pos.x - half_w + half_d, pos.y - ground_h)

	# تصحیح چهار گوشه کف ایزومتریک
	left = Vector2(pos.x - half_w, pos.y - tile_height * width / 2.0)
	right = Vector2(pos.x + half_d, pos.y - tile_height * depth / 2.0)
	back = Vector2(pos.x - half_w + half_d, pos.y - ground_h)

	var roof_front = front - Vector2(0, height)
	var roof_left = left - Vector2(0, height)
	var roof_right = right - Vector2(0, height)
	var roof_back = back - Vector2(0, height)

	# دیوارها
	canvas.draw_colored_polygon(
		PoolVector2Array([roof_left, roof_front, front, left]),
		Color(0.58, 0.44, 0.29)
	)

	canvas.draw_colored_polygon(
		PoolVector2Array([roof_front, roof_right, right, front]),
		Color(0.40, 0.30, 0.21)
	)

	# سقف
	canvas.draw_colored_polygon(
		PoolVector2Array([roof_back, roof_left, roof_front, roof_right]),
		Color(0.32, 0.38, 0.42)
	)

	# خطوط لبه
	var outline = Color(0.16, 0.18, 0.20)
	canvas.draw_line(roof_back, roof_left, outline, 2.0)
	canvas.draw_line(roof_left, roof_front, outline, 2.0)
	canvas.draw_line(roof_front, roof_right, outline, 2.0)
	canvas.draw_line(roof_right, roof_back, outline, 2.0)
	canvas.draw_line(roof_left, left, outline, 2.0)
	canvas.draw_line(roof_right, right, outline, 2.0)
	canvas.draw_line(roof_front, front, outline, 2.0)

	# در ورودی
	var door_width = 12.0 + max(width, depth) * 2.0
	var door_height = 16.0 + max(width, depth) * 2.0
	var door_top = front - Vector2(0, door_height)
	var door = PoolVector2Array([
		door_top - Vector2(door_width / 2.0, 0),
		door_top + Vector2(door_width / 2.0, 0),
		front + Vector2(0, -2.0),
		front - Vector2(door_width / 2.0, 0)
	])
	canvas.draw_colored_polygon(door, Color(0.20, 0.15, 0.11))


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
