
extends Node2D

const ROAD_TEXTURE_PATH = "res://BuildingImages/road_straight.png"

var tile_width = 64
var tile_height = 32
var map_center = Vector2(600, 130)
var roads = []
var road_texture = null

# اندازه ثابت تصویر جاده در هر لوزی
var road_texture_size = Vector2(50, 20)


func _ready():
	if ResourceLoader.exists(ROAD_TEXTURE_PATH):
		road_texture = load(ROAD_TEXTURE_PATH)
	else:
		push_error("Road texture not found: " + ROAD_TEXTURE_PATH)


func _draw():
	if road_texture == null:
		return

	# اول اتصال جاده‌های افقی مجاور را رسم کن
	for road in roads:
		if int(road["direction"]) != 0:
			continue

		var grid_pos = road["grid"]
		var pos = _grid_to_screen(grid_pos)

		if has_road(grid_pos + Vector2(1, 0)):
			var next_pos = _grid_to_screen(grid_pos + Vector2(1, 0))
			_draw_road_connection(pos, next_pos)

	# بعد تصویر اصلی هر جاده را یک بار رسم کن
	for road in roads:
		if int(road["direction"]) != 0:
			continue

		_draw_road_texture(_grid_to_screen(road["grid"]))


func _draw_road_texture(pos):
	var texture_size = road_texture.get_size()

	if texture_size.x <= 0 or texture_size.y <= 0:
		return

	var scale_factor = road_texture_size / texture_size

	draw_set_transform(pos, 0.0, scale_factor)
	draw_texture(
		road_texture,
		-texture_size / 2.0,
		Color(1, 1, 1, 1)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_road_connection(from_pos, to_pos):
	var texture_size = road_texture.get_size()

	if texture_size.x <= 0 or texture_size.y <= 0:
		return

	# فاصله بین مراکز دو لوزی مجاور
	var distance = from_pos.distance_to(to_pos)
	var midpoint = (from_pos + to_pos) / 2.0

	# برش باریک از مرکز بافت؛ از کل تصویر استفاده نمی‌شود
	var strip_width = max(1.0, texture_size.x * 0.25)
	var source_rect = Rect2(
		Vector2((texture_size.x - strip_width) / 2.0, 0),
		Vector2(strip_width, texture_size.y)
	)

	# جهت اتصال فقط از موقعیت دو جاده افقی مجاور گرفته می‌شود
	var angle = (to_pos - from_pos).angle()
	var target_size = Vector2(distance, road_texture_size.y)

	draw_set_transform(midpoint, angle, Vector2.ONE)
	draw_texture_rect_region(
		road_texture,
		Rect2(
			Vector2(-target_size.x / 2.0, -target_size.y / 2.0),
			target_size
		),
		source_rect,
		Color(1, 1, 1, 1)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _grid_to_screen(grid_pos):
	return map_center + Vector2(
		(grid_pos.x - grid_pos.y) * tile_width / 2.0,
		(grid_pos.x + grid_pos.y) * tile_height / 2.0
	)


func add_road(grid_pos, direction):
	# فعلاً فقط جاده افقی شبکه
	if direction != 0:
		return false

	for road in roads:
		if road["grid"] == grid_pos:
			return false

	roads.append({
		"grid": grid_pos,
		"direction": 0
	})

	update()
	print("ROAD ADDED: ", grid_pos)
	return true


func remove_road(grid_pos):
	for i in range(roads.size() - 1, -1, -1):
		if roads[i]["grid"] == grid_pos:
			roads.remove(i)
			update()
			return true

	return false


func has_road(grid_pos):
	for road in roads:
		if road["grid"] == grid_pos and int(road["direction"]) == 0:
			return true

	return false


func set_road_width(value):
	road_texture_size.y = max(1.0, value)
	update()
