extends Node2D

# =========================================
# ZekaCity - RoadSystem.gd
# Godot 3.6
# =========================================

var tile_width = 64
var tile_height = 32
var road_width = 8.0
var road_color = Color(0.25, 0.26, 0.28)
var map_center = Vector2(600, 130)

var roads = []


func _draw():
	for road in roads:
		_draw_road(road["grid"], road["direction"])


# =========================================
# رسم جاده با اتصال به خانه‌های مجاور
# =========================================

func _draw_road(grid_pos, direction):
	var pos = _grid_to_screen(grid_pos)
	var start_point
	var end_point

	if direction == 0:
		start_point = pos + Vector2(-tile_width * 0.25, -tile_height * 0.25)
		end_point = pos + Vector2(tile_width * 0.25, tile_height * 0.25)

		if has_road(grid_pos + Vector2(-1, 0)):
			start_point = pos + Vector2(-tile_width * 0.5, -tile_height * 0.5)

		if has_road(grid_pos + Vector2(1, 0)):
			end_point = pos + Vector2(tile_width * 0.5, tile_height * 0.5)

	else:
		start_point = pos + Vector2(tile_width * 0.25, -tile_height * 0.25)
		end_point = pos + Vector2(-tile_width * 0.25, tile_height * 0.25)

		if has_road(grid_pos + Vector2(0, -1)):
			start_point = pos + Vector2(tile_width * 0.5, -tile_height * 0.5)

		if has_road(grid_pos + Vector2(0, 1)):
			end_point = pos + Vector2(-tile_width * 0.5, tile_height * 0.5)

	draw_line(start_point, end_point, road_color, road_width, true)

	# جهت 0: محور X شبکه
	# جهت 1: محور Y شبکه
	if direction == 0:
		start_point = pos + Vector2(-tile_width * 0.25, -tile_height * 0.25)
		end_point = pos + Vector2(tile_width * 0.25, tile_height * 0.25)

		if has_road(grid_pos + Vector2(-1, 0)):
			start_point = pos + Vector2(-tile_width * 0.5, -tile_height * 0.5)

		if has_road(grid_pos + Vector2(1, 0)):
			end_point = pos + Vector2(tile_width * 0.5, tile_height * 0.5)

	else:
		start_point = pos + Vector2(tile_width * 0.25, -tile_height * 0.25)
		end_point = pos + Vector2(-tile_width * 0.25, tile_height * 0.25)

		if has_road(grid_pos + Vector2(0, -1)):
			start_point = pos + Vector2(tile_width * 0.5, -tile_height * 0.5)

		if has_road(grid_pos + Vector2(0, 1)):
			end_point = pos + Vector2(-tile_width * 0.5, tile_height * 0.5)

	draw_line(start_point, end_point, road_color, road_width, true)


# =========================================
# مختصات شبکه به صفحه
# =========================================

func _grid_to_screen(grid_pos):
	return map_center + Vector2(
		(grid_pos.x - grid_pos.y) * tile_width / 2,
		(grid_pos.x + grid_pos.y) * tile_height / 2
	)


# =========================================
# افزودن جاده
# =========================================

func add_road(grid_pos, direction):
	if direction != 0 and direction != 1:
		push_error("Invalid road direction: " + str(direction))
		return false

	var world = get_node_or_null("../World")

	if world != null and world.is_tile_occupied(grid_pos):
		print("ROAD BLOCKED AT: ", grid_pos)

	for building in world.placed_buildings:
		if building["grid"] == grid_pos:
			print(
				"BLOCKING BUILDING: ",
				building["id"],
				" | GRID: ",
				building["grid"]
			)

	return false

	for road in roads:
		if road["grid"] == grid_pos and road["direction"] == direction:
			print("This road direction already exists on this tile.")
			return false

	roads.append({
		"grid": grid_pos,
		"direction": direction
	})

	update()
	print("ROAD ADDED: ", grid_pos, " direction: ", direction)
	return true


# =========================================
# حذف جاده
# =========================================

func remove_road(grid_pos):
	for i in range(roads.size() - 1, -1, -1):
		if roads[i]["grid"] == grid_pos:
			roads.remove(i)
			update()
			return true

	return false


# =========================================
# بررسی وجود جاده در خانه
# =========================================

func has_road(grid_pos):
	for road in roads:
		if road["grid"] == grid_pos:
			return true

	return false


# =========================================
# تغییر ضخامت جاده
# =========================================

func set_road_width(value):
	road_width = max(1.0, value)
	update()
