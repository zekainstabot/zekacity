extends Node2D

const ROAD_TEXTURE_PATH = "res://BuildingImages/road_straight.png"

const TILE_WIDTH = 64.0
const TILE_HEIGHT = 32.0

var tile_width = TILE_WIDTH
var tile_height = TILE_HEIGHT
var map_center = Vector2(600, 130)

var roads = []
var road_texture = null

# اندازه دقیق تصویر جاده
var road_texture_size = Vector2(64, 32)
var road_offset = Vector2.ZERO

var removal_highlight_enabled = false
var selected_road_for_removal = null


func _ready():
	if ResourceLoader.exists(ROAD_TEXTURE_PATH):
		road_texture = load(ROAD_TEXTURE_PATH)
	else:
		push_error("Road texture not found: " + ROAD_TEXTURE_PATH)

	# پاک‌سازی و ادغام جاده‌های ذخیره‌شده قدیمی
	_normalize_roads()

	update()


func _normalize_roads():
	var unique_roads = []

	for road in roads:
		if typeof(road) != TYPE_DICTIONARY:
			continue

		var grid_pos = road.get("grid", Vector2.ZERO)
		var already_exists = false

		for existing in unique_roads:
			if existing.get("grid", Vector2.ZERO) == grid_pos:
				already_exists = true
				break

		if not already_exists:
			unique_roads.append({
				"grid": grid_pos
			})

	roads = unique_roads


func _draw():
	if road_texture == null:
		return

	for road in roads:
		var grid_pos = road.get("grid", Vector2.ZERO)
		var center = _grid_to_screen(grid_pos) + road_offset

		var tint = Color(1, 1, 1, 1)

		if removal_highlight_enabled:
			tint = Color(1.0, 0.75, 0.25, 1.0)

		if _is_selected_road(grid_pos):
			tint = Color(1.0, 0.2, 0.2, 1.0)

		var destination = Rect2(
			center - road_texture_size / 2.0,
			road_texture_size
		)

		draw_texture_rect(
			road_texture,
			destination,
			false,
			tint
		)


func _grid_to_screen(grid_pos):
	return map_center + Vector2(
		(grid_pos.x - grid_pos.y) * tile_width / 2.0,
		(grid_pos.x + grid_pos.y) * tile_height / 2.0
	)


# direction فقط برای سازگاری با کدهای قدیمی باقی مانده و نادیده گرفته می‌شود.
func add_road(grid_pos, direction = 0):
	if has_road(grid_pos):
		return false

	roads.append({
		"grid": grid_pos
	})

	update()

	print("ROAD ADDED: ", grid_pos)

	return true


func remove_road_piece(grid_pos, direction = 0):
	return remove_road(grid_pos)


func remove_road(grid_pos):
	for i in range(roads.size() - 1, -1, -1):
		if roads[i].get("grid", Vector2.ZERO) == grid_pos:
			roads.remove(i)
			update()
			return true

	return false


func has_road(grid_pos):
	for road in roads:
		if road.get("grid", Vector2.ZERO) == grid_pos:
			return true

	return false


# برای سازگاری با اسکریپت‌های قدیمی
func has_road_direction(grid_pos, direction = 0):
	return has_road(grid_pos)


func set_removal_highlight(enabled):
	removal_highlight_enabled = enabled
	update()


func set_selected_road(road_data):
	selected_road_for_removal = road_data
	update()


func _is_selected_road(grid_pos):
	if selected_road_for_removal == null:
		return false

	return selected_road_for_removal.get(
		"grid",
		Vector2.ZERO
	) == grid_pos


func get_road_at_position(local_mouse_pos):
	var best_road = null
	var best_distance = INF

	for road in roads:
		var grid_pos = road.get("grid", Vector2.ZERO)
		var center = _grid_to_screen(grid_pos) + road_offset

		var hit_rect = Rect2(
			center - road_texture_size / 2.0,
			road_texture_size
		)

		if hit_rect.has_point(local_mouse_pos):
			var distance = local_mouse_pos.distance_squared_to(center)

			if distance < best_distance:
				best_distance = distance

				best_road = {
					"grid": grid_pos
				}

	return best_road


func set_road_width(value):
	road_texture_size.y = max(1.0, float(value))
	update()


func set_road_size(width, height):
	road_texture_size = Vector2(
		max(1.0, float(width)),
		max(1.0, float(height))
	)
	update()


func set_horizontal_offset(x, y):
	road_offset = Vector2(float(x), float(y))
	update()


func set_vertical_offset(x, y):
	road_offset = Vector2(float(x), float(y))
	update()


# توابع قدیمی برای جلوگیری از خطای اسکریپت‌های وابسته
func set_left_end_shift(value):
	pass


func set_deformation_columns(value):
	pass
