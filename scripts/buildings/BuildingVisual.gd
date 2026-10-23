extends Node2D

var world = null
var building_id = ""
var grid_pos = Vector2.ZERO
var building_index = -1
var visual_alpha = 1.0
var drawer = null
var building_texture = null
var visible_bounds = Rect2()
var has_visible_bounds = false

# مثبت: پایین‌تر، منفی: بالاتر
const GROUND_OFFSET_Y = 0.0

const BUILDING_IMAGE_PATHS = {
	"small_house": "res://BuildingImages/small_house.png",
	"normal_house": "res://BuildingImages/normal_house.png",
	"low_apartment": "res://BuildingImages/low_apartment.png",
	"high_apartment": "res://BuildingImages/high_apartment.png",
	"residential_tower": "res://BuildingImages/residential_tower.png",
	"road": "res://BuildingImages/road.png",
	"grocery_store": "res://BuildingImages/grocery_store.png",
	"school": "res://BuildingImages/school.png",
	"clinic": "res://BuildingImages/clinic.png",
	"hospital": "res://BuildingImages/hospital.png",
	"small_park": "res://BuildingImages/small_park.png",
	"small_warehouse": "res://BuildingImages/small_warehouse.png",
	"medium_warehouse": "res://BuildingImages/medium_warehouse.png",
	"large_warehouse": "res://BuildingImages/large_warehouse.png",
	"huge_warehouse": "res://BuildingImages/huge_warehouse.png"
}


func setup(world_node, new_building_id, new_grid_pos, new_building_index, new_alpha = 1.0):
	world = world_node
	building_id = new_building_id
	grid_pos = new_grid_pos
	building_index = new_building_index
	visual_alpha = clamp(new_alpha, 0.0, 1.0)

	drawer = _get_drawer(building_id)
	building_texture = _get_building_texture(building_id)

	if building_texture != null:
		_calculate_visible_bounds()

	var footprint = world.building_footprints.get_footprint(building_id)

	var visual_grid_pos = grid_pos + Vector2(
		(footprint.x - 1.0) / 2.0,
		(footprint.y - 1.0) / 2.0
	)

	position = world.grid_to_screen(
		visual_grid_pos,
		Vector2(600, 130)
	)

	z_index = int((grid_pos.x + grid_pos.y) * 10)
	modulate = Color(1.0, 1.0, 1.0, visual_alpha)
	update()


func _calculate_visible_bounds():
	has_visible_bounds = false

	var image = building_texture.get_data()
	if image == null:
		return

	image.lock()

	var image_width = image.get_width()
	var image_height = image.get_height()

	var min_x = image_width
	var min_y = image_height
	var max_x = -1
	var max_y = -1

	for y in range(image_height):
		for x in range(image_width):
			if image.get_pixel(x, y).a > 0.05:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)

	image.unlock()

	if max_x < 0:
		return

	visible_bounds = Rect2(
		Vector2(min_x, min_y),
		Vector2(max_x - min_x + 1, max_y - min_y + 1)
	)

	has_visible_bounds = true


func set_visual_alpha(value):
	visual_alpha = clamp(value, 0.0, 1.0)
	modulate = Color(1.0, 1.0, 1.0, visual_alpha)
	update()


func _get_building_texture(id):
	if not BUILDING_IMAGE_PATHS.has(id):
		return null

	var image_path = BUILDING_IMAGE_PATHS[id]

	if ResourceLoader.exists(image_path):
		return load(image_path)

	return null


func _get_drawer(id):
	if id in ["small_house", "normal_house", "low_apartment", "high_apartment", "residential_tower"]:
		return world.residential_buildings

	if id in ["grocery_store", "bakery", "restaurant", "office", "shopping_mall", "factory", "mineral_market"]:
		return world.commercial_buildings

	if id in ["small_warehouse", "medium_warehouse", "large_warehouse", "huge_warehouse"]:
		return world.warehouse_buildings

	if id in ["school", "university"]:
		return world.education_buildings

	if id in ["clinic", "hospital"]:
		return world.healthcare_buildings

	if id in ["police_station", "fire_station", "city_hall"]:
		return world.public_buildings

	if id in ["water_tower", "power_station", "sewage_plant", "waste_facility"]:
		return world.utility_buildings

	if id in ["small_park", "playground", "sports_center", "cultural_center"]:
		return world.recreation_buildings

	return null


func _draw():
	if world == null:
		return

	if building_texture != null:
		var texture_size = building_texture.get_size()
		var target_size = Vector2(58, 58)

		var scale_factor = min(
			target_size.x / texture_size.x,
			target_size.y / texture_size.y
		)

		var draw_position = Vector2.ZERO

		if has_visible_bounds:
			# مرکز افقی تصویر قابل مشاهده
			draw_position.x = -(
				visible_bounds.position.x
				+ visible_bounds.size.x / 2.0
			)

			# پایه تصویر روی نوک پایینی لوزی
			draw_position.y = (
				texture_size.y / 2.0
				- visible_bounds.end.y
				- 5.0 / scale_factor
			)
		else:
			draw_position = -texture_size / 2.0

		draw_set_transform(
			draw_position * scale_factor,
			0.0,
			Vector2(scale_factor, scale_factor)
		)

		draw_texture(building_texture, Vector2.ZERO)

		draw_set_transform(
			Vector2.ZERO,
			0.0,
			Vector2.ONE
		)

		return

	if drawer != null:
		drawer.draw_building(
			self,
			building_id,
			Vector2.ZERO
		)
