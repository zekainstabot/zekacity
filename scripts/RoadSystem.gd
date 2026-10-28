extends Node2D

const ROAD_HORIZONTAL_PATH = "res://BuildingImages/road_straight.png"
const ROAD_VERTICAL_PATH = "res://BuildingImages/road_vertical.png"

var tile_width = 64
var tile_height = 32
var map_center = Vector2(600, 130)

var roads = []

var road_horizontal_texture = null
var road_vertical_texture = null

# اندازه نمایش هر تصویر جاده
var road_texture_size = Vector2(50, 20)


func _ready():
	if ResourceLoader.exists(ROAD_HORIZONTAL_PATH):
		road_horizontal_texture = load(ROAD_HORIZONTAL_PATH)
	else:
		push_error(
			"Horizontal road texture not found: "
			+ ROAD_HORIZONTAL_PATH
		)

	if ResourceLoader.exists(ROAD_VERTICAL_PATH):
		road_vertical_texture = load(ROAD_VERTICAL_PATH)
	else:
		push_error(
			"Vertical road texture not found: "
			+ ROAD_VERTICAL_PATH
		)

	update()


func _draw():
	for road in roads:
		var grid_pos = road.get("grid", Vector2.ZERO)
		var direction = int(road.get("direction", 0))
		var texture = _get_road_texture(direction)

		if texture == null:
			continue

		var screen_pos = _grid_to_screen(grid_pos)

		_draw_road_texture(
			texture,
			screen_pos
		)


func _get_road_texture(direction):
	if direction == 0:
		return road_horizontal_texture

	if direction == 1:
		return road_vertical_texture

	return null


func _draw_road_texture(texture, pos):
	if texture == null:
		return

	var texture_size = texture.get_size()

	if texture_size.x <= 0 or texture_size.y <= 0:
		return

	var scale_factor = Vector2(
		road_texture_size.x / texture_size.x,
		road_texture_size.y / texture_size.y
	)

	draw_set_transform(
		pos,
		0.0,
		scale_factor
	)

	draw_texture(
		texture,
		-texture_size / 2.0,
		Color(1, 1, 1, 1)
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)


func _grid_to_screen(grid_pos):
	return map_center + Vector2(
		(grid_pos.x - grid_pos.y) * tile_width / 2.0,
		(grid_pos.x + grid_pos.y) * tile_height / 2.0
	)


func add_road(grid_pos, direction):
	if direction != 0 and direction != 1:
		push_error("Invalid road direction: " + str(direction))
		return false

	# اجازه نده یک جاده با همان جهت دوباره ساخته شود.
	# یک خانه می‌تواند هر دو جهت جاده را داشته باشد.
	for road in roads:
		if (
			road["grid"] == grid_pos
			and int(road["direction"]) == direction
		):
			return false

	roads.append({
		"grid": grid_pos,
		"direction": direction
	})

	update()

	print(
		"ROAD ADDED: ",
		grid_pos,
		" | Direction: ",
		direction
	)

	return true


func remove_road(grid_pos):
	var removed = false

	for i in range(roads.size() - 1, -1, -1):
		if roads[i]["grid"] == grid_pos:
			roads.remove(i)
			removed = true

	if removed:
		update()

	return removed


func has_road(grid_pos):
	for road in roads:
		if road["grid"] == grid_pos:
			return true

	return false


func has_road_direction(grid_pos, direction):
	for road in roads:
		if (
			road["grid"] == grid_pos
			and int(road["direction"]) == direction
		):
			return true

	return false


func set_road_width(value):
	road_texture_size.y = max(1.0, float(value))
	update()
