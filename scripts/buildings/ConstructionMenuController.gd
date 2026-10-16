
extends Reference

var world = null
var submenu_menu = null
var menu_building_ids = {}
var next_building_menu_id = 1

var category_buildings = {
	100: {
		"name": "Houses",
		"items": [
			"small_house",
			"normal_house",
			"low_apartment",
			"high_apartment",
			"residential_tower"
		]
	},
	102: {
		"name": "Parks and Recreation",
		"items": [
			"small_park",
			"playground",
			"sports_center",
			"cultural_center"
		]
	},
	103: {
		"name": "Education",
		"items": ["school", "university"]
	},
	104: {
		"name": "Healthcare",
		"items": ["clinic", "hospital"]
	},
	105: {
		"name": "Businesses",
		"items": [
			"grocery_store",
			"bakery",
			"restaurant",
			"office",
			"shopping_mall",
			"factory"
		]
	},
	106: {
		"name": "Utilities",
		"items": [
			"water_tower",
			"power_station",
			"sewage_plant",
			"waste_facility"
		]
	},
	107: {
		"name": "Public Services",
		"items": [
			"city_hall",
			"police_station",
			"fire_station"
		]
	}
}


func initialize(world_node, submenu_node):
	world = world_node
	submenu_menu = submenu_node

	if not submenu_menu.is_connected(
		"id_pressed",
		self,
		"_on_SubmenuMenu_id_pressed"
	):
		submenu_menu.connect(
			"id_pressed",
			self,
			"_on_SubmenuMenu_id_pressed"
		)



func on_build_button_pressed():
	if world == null:
		return

	var menu = world.get_node_or_null("../UI/ConstructionMenu")
	if menu == null:
		push_error("ConstructionMenu NOT FOUND")
		return

	menu.clear()
	menu.add_item("Houses", 100)
	menu.add_item("Roads", 101)
	menu.add_item("Parks and Recreation", 102)
	menu.add_item("Education", 103)
	menu.add_item("Healthcare", 104)
	menu.add_item("Businesses", 105)
	menu.add_item("Utilities", 106)
	menu.add_item("Public Services", 107)

	menu.rect_size = Vector2(220, 270)
	menu.popup()


func on_category_selected(id):
	if world == null:
		return

	if id == 108:
		world._buy_selected_land()
		return

	if submenu_menu == null:
		push_error("BuildingSubmenu NOT FOUND")
		return

	submenu_menu.clear()
	menu_building_ids.clear()
	next_building_menu_id = 1

	if id == 101:
		submenu_menu.add_item("Road A", 201)
		submenu_menu.add_item("Road B", 202)
		submenu_menu.rect_position = world.get_global_mouse_position()
		submenu_menu.popup()
		return

	if not category_buildings.has(id):
		push_error("UNKNOWN CATEGORY ID: " + str(id))
		return

	var items = category_buildings[id]["items"]

	for building_id in items:
		var menu_id = next_building_menu_id
		next_building_menu_id += 1

		menu_building_ids[menu_id] = building_id

		var display_name = world.building_names.get(
			building_id,
			building_id.replace("_", " ").capitalize()
		)

		submenu_menu.add_item(display_name, menu_id)

	submenu_menu.rect_position = world.get_global_mouse_position()
	submenu_menu.popup()



func _on_SubmenuMenu_id_pressed(id):
	if world == null:
		return

	if id == 201:
		world.selected_building_for_placement = ""
		world._place_road(0)
		return

	if id == 202:
		world.selected_building_for_placement = ""
		world._place_road(1)
		return

	if not menu_building_ids.has(id):
		push_error("UNKNOWN SUBMENU ID: " + str(id))
		return

	var building_id = menu_building_ids[id]

	world.road_placement_direction = -1
	world.selected_building_for_placement = building_id

	print(
		"BUILDING SELECTED: ",
		building_id,
		" | Click a valid tile to place it."
	)
