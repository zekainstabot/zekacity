
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

# حداکثر اندازه تصویر با حفظ نسبت طول و عرض
const BUILDING_TARGET_SIZE = Vector2(64, 64)

# تنظیم جزئی ارتفاع تصویر
const GROUND_OFFSET_Y = 0.0

# تنظیم جداگانه خانه کوچک
const SMALL_HOUSE_OFFSET_Y = 8.0

const BUILDING_IMAGE_PATHS = {
	"small_house": "res://BuildingImages/small_house.png",
	"normal_house": "res://BuildingImages/normal_house.png",
	"low_apartment": "res://BuildingImages/low_apartment.png",
	"high_apartment": "res://BuildingImages/high_apartment.png",
	"residential_tower": "res://BuildingImages/residential_tower.png",
	"grocery_store": "res://BuildingImages/grocery_store.png",
	"bakery": "res://BuildingImages/grocery_store.png",
	"restaurant": "res://BuildingImages/grocery_store.png",
	"office": "res://BuildingImages/high_apartment.png",
	"shopping_mall": "res://BuildingImages/high_apartment.png",
	"factory": "res://BuildingImages/medium_warehouse.png",
	"mineral_market": "res://BuildingImages/iron_mine.png",
	"school": "res://BuildingImages/school.png",
	"university": "res://BuildingImages/high_school.png",
	"clinic": "res://BuildingImages/hospital.png",
	"hospital": "res://BuildingImages/hospital.png",
	"small_park": "res://BuildingImages/small_park.png",
	"small_warehouse": "res://BuildingImages/small_warehouse.png",
	"medium_warehouse": "res://BuildingImages/medium_warehouse.png",
	"large_warehouse": "res://BuildingImages/medium_warehouse.png",
	"huge_warehouse": "res://BuildingImages/medium_warehouse.png"
}


func setup(world_node, new_building_id, new_grid_pos,
		new_building_index, new_alpha = 1.0):

	world = world_node
	building_id = str(new_building_id)
	grid_pos = new_grid_pos
	building_index = new_building_index
	visual_alpha = clamp(new_alpha, 0.0, 1.0)

	drawer = _get_drawer(building_id)
	building_texture = _get_building_texture(building_id)

	has_visible_bounds = false

	if building_texture != null:
		_calculate_visible_bounds()

	# محدوده اشغال‌شده روی شبکه
	var footprint = Vector2.ONE

	if world != null and world.building_footprints != null:
		footprint = world.building_footprints.get_footprint(
			building_id
		)

	# مرکز محدوده ساختمان روی شبکه
	var visual_grid_pos = grid_pos + Vector2(
		(footprint.x - 1.0) / 2.0,
		(footprint.y - 1.0) / 2.0
	)

	# حفظ مختصات و دوربین فعلی
	if world != null:
		position = world.grid_to_screen(
			visual_grid_pos,
			Vector2(600, 130)
		)

	z_index = int((grid_pos.x + grid_pos.y) * 10)

	modulate = Color(
		1.0,
		1.0,
		1.0,
		visual_alpha
	)

	update()


func _calculate_visible_bounds():
	has_visible_bounds = false

	if building_texture == null:
		return

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
		Vector2(
			max_x - min_x + 1,
			max_y - min_y + 1
		)
	)

	has_visible_bounds = true


func set_visual_alpha(value):
	visual_alpha = clamp(value, 0.0, 1.0)

	modulate = Color(
		1.0,
		1.0,
		1.0,
		visual_alpha
	)

	update()


func _get_building_texture(id):
	if not BUILDING_IMAGE_PATHS.has(id):
		return null

	var image_path = BUILDING_IMAGE_PATHS[id]

	if ResourceLoader.exists(image_path):
		return load(image_path)

	return null


func _get_drawer(id):
	if world == null:
		return null

	if id in [
		"small_house",
		"normal_house",
		"low_apartment",
		"high_apartment",
		"residential_tower"
	]:
		return world.residential_buildings

	if id in [
		"grocery_store",
		"bakery",
		"restaurant",
		"office",
		"shopping_mall",
		"factory",
		"mineral_market"
	]:
		return world.commercial_buildings

	if id in [
		"small_warehouse",
		"medium_warehouse",
		"large_warehouse",
		"huge_warehouse"
	]:
		return world.warehouse_buildings

	if id in ["school", "university"]:
		return world.education_buildings

	if id in ["clinic", "hospital"]:
		return world.healthcare_buildings

	if id in [
		"police_station",
		"fire_station",
		"city_hall"
	]:
		return world.public_buildings

	if id in [
		"water_tower",
		"power_station",
		"sewage_plant",
		"waste_facility"
	]:
		return world.utility_buildings

	if id in [
		"small_park",
		"playground",
		"sports_center",
		"cultural_center"
	]:
		return world.recreation_buildings

	return null


func _draw():
	if world == null:
		return

	if building_texture != null:
		var texture_size = building_texture.get_size()

		if texture_size.x <= 0 or texture_size.y <= 0:
			return

		# کوچک‌سازی متناسب، بدون چرخاندن تصویر
		var scale_factor = min(
			BUILDING_TARGET_SIZE.x / texture_size.x,
			BUILDING_TARGET_SIZE.y / texture_size.y
		)

		# نقطه اتصال افقی و عمودی تصویر
		var anchor_x = texture_size.x / 2.0
		var anchor_y = texture_size.y

		# نادیده گرفتن حاشیه‌های شفاف PNG
		if has_visible_bounds:
			anchor_x = (
				visible_bounds.position.x
				+ visible_bounds.size.x / 2.0
			)

			anchor_y = visible_bounds.end.y

		# اصلاح جداگانه ارتفاع خانه کوچک
		var extra_offset_y = 0.0

		if building_id == "small_house":
			extra_offset_y = SMALL_HOUSE_OFFSET_Y

		var draw_position = Vector2(
			-anchor_x * scale_factor,
			-anchor_y * scale_factor
			+ GROUND_OFFSET_Y
			+ extra_offset_y
		)

		draw_set_transform(
			draw_position,
			0.0,
			Vector2(scale_factor, scale_factor)
		)

		draw_texture(
			building_texture,
			Vector2.ZERO
		)

		# بازگرداندن تبدیل رسم
		draw_set_transform(
			Vector2.ZERO,
			0.0,
			Vector2.ONE
		)

		return

	# روش رسم جایگزین اگر تصویر وجود نداشته باشد
	if drawer != null:
		drawer.draw_building(
			self,
			building_id,
			Vector2.ZERO
		)
