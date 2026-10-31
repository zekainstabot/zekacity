extends Node2D

const ROAD_HORIZONTAL_PATH = "res://BuildingImages/road_straight.png"
const ROAD_VERTICAL_PATH = "res://BuildingImages/road_vertical.png"

const TILE_WIDTH = 64.0
const TILE_HEIGHT = 32.0

var tile_width = TILE_WIDTH
var tile_height = TILE_HEIGHT
var map_center = Vector2(600, 130)

var roads = []

var road_horizontal_texture = null
var road_vertical_texture = null

# Exact isometric tile dimensions.
var road_texture_size = Vector2(64, 32)

var horizontal_offset = Vector2.ZERO
var vertical_offset = Vector2.ZERO

# Kept for compatibility with existing code.
var left_end_shift = 0.0
var deformation_columns = 1

# Road removal mode
var removal_highlight_enabled = false
var selected_road_for_removal = null


func _ready():
	if ResourceLoader.exists(ROAD_HORIZONTAL_PATH):
		road_horizontal_texture = load(ROAD_HORIZONTAL_PATH)
	else:
		push_error("Horizontal road texture not found: " + ROAD_HORIZONTAL_PATH)

	if ResourceLoader.exists(ROAD_VERTICAL_PATH):
		road_vertical_texture = load(ROAD_VERTICAL_PATH)
	else:
		push_error("Vertical road texture not found: " + ROAD_VERTICAL_PATH)

	update()


func _draw():
	for road in roads:
		var grid_pos = road.get("grid", Vector2.ZERO)
		var direction = int(road.get("direction", 0))

		var texture = _get_road_texture(direction)

		if texture == null:
			continue

		var screen_pos = _grid_to_screen(grid_pos)
		var offset = _get_road_offset(direction)
		var center = screen_pos + offset

		var tint = Color(1, 1, 1, 1)

		if removal_highlight_enabled:
			tint = Color(1.0, 0.75, 0.25, 1.0)

		if _is_selected_road(grid_pos, direction):
			tint = Color(1.0, 0.2, 0.2, 1.0)

		_draw_road_texture(texture, center, tint)


func _get_road_texture(direction):
	if direction == 0:
		return road_horizontal_texture

	if direction == 1:
		return road_vertical_texture

	return null


func _get_road_offset(direction):
	if direction == 0:
		return horizontal_offset

	if direction == 1:
		return vertical_offset

	return Vector2.ZERO


# Draws the complete road tile without deformation.
func _draw_road_texture(texture, center, tint = Color(1, 1, 1, 1)):
	if texture == null:
		return

	var overlap = 0.5

	var destination = Rect2(
	center - road_texture_size / 2.0 - Vector2(overlap, overlap),
	road_texture_size + Vector2(overlap * 2.0, overlap * 2.0)
)

	draw_texture_rect(
		texture,
		destination,
		false,
		tint
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

	for road in roads:
		if road.get("grid", Vector2.ZERO) == grid_pos:
			if int(road.get("direction", -1)) == direction:
				return false

	roads.append({
		"grid": grid_pos,
		"direction": direction
	})

	update()

	print("ROAD ADDED: ", grid_pos, " | Direction: ", direction)

	return true


# Removes only one exact road piece.
func remove_road_piece(grid_pos, direction):
	for i in range(roads.size() - 1, -1, -1):
		var road = roads[i]

		if road.get("grid", Vector2.ZERO) == grid_pos:
			if int(road.get("direction", -1)) == direction:
				roads.remove(i)
				update()
				return true

	return false


# Keeps compatibility with existing code.
func remove_road(grid_pos):
	var removed = false

	for i in range(roads.size() - 1, -1, -1):
		if roads[i].get("grid", Vector2.ZERO) == grid_pos:
			roads.remove(i)
			removed = true

	if removed:
		update()

	return removed


func has_road(grid_pos):
	for road in roads:
		if road.get("grid", Vector2.ZERO) == grid_pos:
			return true

	return false


func has_road_direction(grid_pos, direction):
	for road in roads:
		if road.get("grid", Vector2.ZERO) == grid_pos:
			if int(road.get("direction", -1)) == direction:
				return true

	return false


func set_removal_highlight(enabled):
	removal_highlight_enabled = enabled
	update()


func set_selected_road(road_data):
	selected_road_for_removal = road_data
	update()


func _is_selected_road(grid_pos, direction):
	if selected_road_for_removal == null:
		return false

	return (
		selected_road_for_removal.get("grid", Vector2.ZERO) == grid_pos
		and
		int(selected_road_for_removal.get("direction", -1)) == direction
	)


# Finds the closest road under the mouse.
func get_road_at_position(local_mouse_pos):
	var best_road = null
	var best_distance = INF

	for road in roads:
		var grid_pos = road.get("grid", Vector2.ZERO)
		var direction = int(road.get("direction", 0))

		var center = _grid_to_screen(grid_pos) + _get_road_offset(direction)

		var hit_rect = Rect2(
			center - road_texture_size / 2.0,
			road_texture_size
		)

		if hit_rect.has_point(local_mouse_pos):
			var distance = local_mouse_pos.distance_squared_to(center)

			if distance < best_distance:
				best_distance = distance

				best_road = {
					"grid": grid_pos,
					"direction": direction
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
	horizontal_offset = Vector2(float(x), float(y))
	update()


func set_vertical_offset(x, y):
	vertical_offset = Vector2(float(x), float(y))
	update()


# Kept for compatibility. No deformation is applied.
func set_left_end_shift(value):
	left_end_shift = float(value)


func set_deformation_columns(value):
	deformation_columns = max(1, int(value))
