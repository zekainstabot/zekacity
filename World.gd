
extends Node2D

# =========================================
# ZekaCity - World.gd
# Godot 3.6
# =========================================

var tile_width = 64
var tile_height = 32
var grid_size = 25

var selected_x = 0
var selected_y = 0

var placed_buildings = []
var building_system = null

var building_action_panel = null

var building_visuals_root = null

var building_visibility = preload(
	"res://scripts/buildings/BuildingVisibility.gd"
).new()

var building_interaction_controller = preload(
	"res://scripts/buildings/BuildingInteractionController.gd"
).new()

var building_hit_tester = preload(
	"res://scripts/buildings/BuildingHitTester.gd"
).new()

var selected_building_index = -1
var submenu_menu = null

var next_building_menu_id = 1
var menu_building_ids = {}

var residential_buildings = preload(
	"res://scripts/buildings/ResidentialBuildings.gd"
).new()

var commercial_buildings = preload(
	"res://scripts/buildings/CommercialBuildings.gd"
).new()

var public_buildings = preload(
	"res://scripts/buildings/PublicBuildings.gd"
).new()

var education_buildings = preload(
	"res://scripts/buildings/EducationBuildings.gd"
).new()

var healthcare_buildings = preload(
	"res://scripts/buildings/HealthcareBuildings.gd"
).new()

var utility_buildings = preload(
	"res://scripts/buildings/UtilityBuildings.gd"
).new()

var recreation_buildings = preload(
	"res://scripts/buildings/RecreationBuildings.gd"
).new()

var land_system = preload(
	"res://scripts/land/LandSystem.gd"
).new()

var city_treasury = preload(
	"res://scripts/economy/CityTreasury.gd"
).new()

var land_renderer = preload(
	"res://scripts/land/LandRenderer.gd"
).new()

var building_footprints = preload(
	"res://scripts/buildings/BuildingFootprints.gd"
).new()

var building_placement = preload(
	"res://scripts/buildings/BuildingPlacement.gd"
).new()

var building_actions = preload(
	"res://scripts/buildings/BuildingActions.gd"
).new()

var building_action_dialog = null
var building_action_menu = null
var pending_demolition_index = -1
var moving_building_index = -1
var moving_building_origin = Vector2(-1, -1)

var land_selection = preload(
	"res://scripts/land/LandSelection.gd"
).new()

var land_purchase = preload(
	"res://scripts/land/LandPurchase.gd"
).new()


var treasury_label = null
var land_purchase_dialog = null
var pending_land_grid = Vector2(0, 0)



var building_names = {
	"small_house": "Small House",
	"normal_house": "House",
	"low_apartment": "Low-rise Apartments",
	"high_apartment": "High-rise Apartments",
	"residential_tower": "Residential Tower",
	"grocery_store": "Grocery Store",
	"bakery": "Bakery",
	"restaurant": "Restaurant",
	"office": "Office Building",
	"shopping_mall": "Shopping Mall",
	"factory": "Factory",
	"water_tower": "Water Tower",
	"power_station": "Power Station",
	"sewage_plant": "Sewage Plant",
	"waste_facility": "Waste Facility",
	"school": "Elementary School",
	"clinic": "Clinic",
	"hospital": "Hospital",
	"police_station": "Police Station",
	"fire_station": "Fire Station",
	"city_hall": "City Hall",
	"small_park": "Small Park",
	"playground": "Playground",
	"sports_center": "Sports Center",
	"university": "University",
	"cultural_center": "Cultural Center"
}


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
		"name": "Parks",
		"items": [
			"small_park",
			"playground",
			"sports_center",
			"cultural_center"
		]
	},
	103: {
		"name": "Education",
		"items": [
			"school",
			"university"
		]
	},
	104: {
		"name": "Healthcare",
		"items": [
			"clinic",
			"hospital"
		]
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


# =========================================
# INITIALIZATION
# =========================================

func _ready():
	print("CITY TREASURY INITIALIZED: ", city_treasury.get_balance())
	
	var ui = get_node_or_null("../UI")

	if ui != null:
		treasury_label = Label.new()
		treasury_label.name = "TreasuryLabel"
		treasury_label.rect_position = Vector2(20, 60)
		ui.add_child(treasury_label)
		_update_treasury_label()
	else:
		push_error("UI node NOT FOUND")

	land_purchase_dialog = ConfirmationDialog.new()
	land_purchase_dialog.name = "LandPurchaseDialog"
	add_child(land_purchase_dialog)
	land_purchase_dialog.connect(
		"confirmed",
		self,
		"_confirm_land_purchase"
	)

	land_system.initialize(grid_size)
	if placed_buildings.empty():
		placed_buildings.append({
			"grid": Vector2(0, 0),
			"id": "small_house"
		})

	submenu_menu = PopupMenu.new()
	submenu_menu.name = "BuildingSubmenu"
	submenu_menu.set_as_toplevel(true)
	add_child(submenu_menu)

	submenu_menu.connect(
		"id_pressed",
		self,
		"_on_SubmenuMenu_id_pressed"
	)

	building_system = get_node_or_null("../BuildingSystem")

	if building_system == null:
		push_error("BuildingSystem node NOT FOUND")
	else:
		building_system.tile_width = tile_width
		building_system.tile_height = tile_height
		building_system.set_buildings(placed_buildings)
		_refresh_building_visuals()
		
	building_visuals_root = Node2D.new()
	building_visuals_root.name = "BuildingVisuals"
	add_child(building_visuals_root)

	_refresh_building_visuals()
	building_action_panel = preload(
		"res://scripts/buildings/BuildingActionPanel.gd"
	).new()

	building_action_panel.name = "BuildingActionPanel"
	add_child(building_action_panel)

	building_action_panel.connect(
		"building_action_selected",
		self,
		"_on_BuildingActionMenu_id_pressed"
	)

	building_action_dialog = ConfirmationDialog.new()
	building_action_dialog.name = "BuildingActionDialog"
	add_child(building_action_dialog)

	building_action_dialog.connect(
		"confirmed",
		self,
		"_confirm_building_demolition"
	)
	update()

# =========================================
# ISOMETRIC GRID
# =========================================

func grid_to_screen(grid_pos, center):
	return center + Vector2(
		(grid_pos.x - grid_pos.y) * tile_width / 2,
		(grid_pos.x + grid_pos.y) * tile_height / 2
	)


func get_tile_polygon(pos):
	return PoolVector2Array([
		pos + Vector2(0, -tile_height / 2),
		pos + Vector2(tile_width / 2, 0),
		pos + Vector2(0, tile_height / 2),
		pos + Vector2(-tile_width / 2, 0)
	])


func is_tile_occupied(grid_pos):
	for building in placed_buildings:
		if building["grid"] == grid_pos:
			return true

	return false


func has_park_at(grid_pos):
	for building in placed_buildings:
		if building["grid"] == grid_pos:
			if building["id"] == "small_park":
				return true

	return false


# =========================================
# DRAW CITY GRID
# =========================================

func _draw():
	var center = Vector2(600, 130)

	land_renderer.draw_tiles(
		self,
		land_system,
		grid_size,
		center,
		selected_x,
		selected_y
	)


func _refresh_building_visuals():
	if building_visuals_root == null:
		return

	for child in building_visuals_root.get_children():
		building_visuals_root.remove_child(child)
		child.free()

	var visual_script = preload(
		"res://scripts/buildings/BuildingVisual.gd"
	)

	for i in range(placed_buildings.size()):
		var building = placed_buildings[i]
		var visual = visual_script.new()

		building_visuals_root.add_child(visual)

		var alpha = building_visibility.get_building_alpha(
			i,
			placed_buildings
		)

		visual.setup(
			self,
			building["id"],
			building["grid"],
			i,
			alpha
		)

# =========================================
# BUILDING DRAW DISPATCHER
# =========================================

func _draw_building(building_id, grid_pos, center):
	var footprint = building_footprints.get_footprint(building_id)

	var visual_grid_pos = grid_pos + Vector2(
		(footprint.x - 1.0) / 2.0,
		(footprint.y - 1.0) / 2.0
	)

	var pos = grid_to_screen(visual_grid_pos, center)

	if building_id in [
		"small_house",
		"normal_house",
		"low_apartment",
		"high_apartment",
		"residential_tower"
	]:
		residential_buildings.draw_building(
			self,
			building_id,
			pos
		)
		return

	if building_id in [
		"grocery_store",
		"bakery",
		"restaurant",
		"office",
		"shopping_mall",
		"factory"
	]:
		commercial_buildings.draw_building(
			self,
			building_id,
			pos
		)
		return

	if building_id == "school":
		education_buildings.draw_building(
			self,
			building_id,
			pos
		)
		return

	if building_id == "university":
		education_buildings.draw_building(
			self,
			building_id,
			pos
		)
		return

	if building_id in ["clinic", "hospital"]:
		healthcare_buildings.draw_building(
			self,
			building_id,
			pos
		)
		return

	if building_id in [
		"police_station",
		"fire_station",
		"city_hall"
	]:
		public_buildings.draw_building(
			self,
			building_id,
			pos
		)
		return

	if building_id in [
		"water_tower",
		"power_station",
		"sewage_plant",
		"waste_facility"
	]:
		utility_buildings.draw_building(
			self,
			building_id,
			pos
		)
		return

	if building_id in [
		"small_park",
		"playground",
		"sports_center",
		"cultural_center"
	]:
		recreation_buildings.draw_building(
			self,
			building_id,
			pos
		)


# =========================================
# CONSTRUCTION MENU
# =========================================

func _on_BuildHouseButton_pressed():
	print("BUILD BUTTON PRESSED")

	var menu = get_node_or_null("../UI/ConstructionMenu")

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
	menu.add_item("Buy Selected Land", 108)

	menu.rect_size = Vector2(220, 300)
	menu.popup()




func _on_ConstructionMenu_id_pressed(id):
	print("CATEGORY SELECTED: ", id)

	if id == 108:
		_buy_selected_land()
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
		submenu_menu.rect_position = get_global_mouse_position()
		submenu_menu.popup()
		return

	if not category_buildings.has(id):
		push_error("UNKNOWN CATEGORY ID: " + str(id))
		return

	var items = category_buildings[id]["items"]

	for current_building_id in items:
		var menu_id = next_building_menu_id
		next_building_menu_id += 1

		menu_building_ids[menu_id] = current_building_id

		var display_name = building_names.get(
			current_building_id,
			current_building_id.replace("_", " ").capitalize()
		)

		submenu_menu.add_item(display_name, menu_id)

	print("SUBMENU ITEMS: ", items)

	submenu_menu.rect_position = get_global_mouse_position()
	submenu_menu.popup()


func _on_SubmenuMenu_id_pressed(id):
	print("SUBMENU ITEM SELECTED: ", id)

	if id == 201:
		_place_road(0)
		return

	if id == 202:
		_place_road(1)
		return

	if not menu_building_ids.has(id):
		push_error("UNKNOWN SUBMENU ID: " + str(id))
		return

	var selected_building_id = menu_building_ids[id]

	print("SELECTED BUILDING: ", selected_building_id)

	_place_building(selected_building_id)


# =========================================
# PLACING BUILDINGS
# =========================================


func _place_building(building_id):
	var grid_pos = Vector2(selected_x, selected_y)
	var road_system = get_node_or_null("../RoadSystem")

	var can_place = building_placement.can_place_building(
		building_id,
		grid_pos,
		grid_size,
		placed_buildings,
		building_footprints,
		land_system,
		road_system
	)

	if not can_place:
		var error_code = building_placement.get_placement_error(
			building_id,
			grid_pos,
			grid_size,
			placed_buildings,
			building_footprints,
			land_system,
			road_system
		)

		print("BUILDING PLACEMENT FAILED: ", error_code)
		return

	placed_buildings.append({
		"grid": grid_pos,
		"id": building_id
	})

	if building_system != null:
		building_system.set_buildings(placed_buildings)

	_refresh_building_visuals()
	update()


# =========================================
# PLACING ROADS
# =========================================

func _place_road(direction):
	var road_system = get_node_or_null("../RoadSystem")

	if road_system == null:
		push_error("RoadSystem node NOT FOUND")
		return

	var grid_pos = Vector2(selected_x, selected_y)

	if is_tile_occupied(grid_pos):
		print("Cannot build a road on a building tile: ", grid_pos)
		return

	var added = road_system.add_road(grid_pos, direction)

	if added:
		print("ROAD ADDED: ", grid_pos)

func _find_building_at_position(mouse_pos):
	return building_hit_tester.find_building_at_position(
		mouse_pos,
		placed_buildings,
		building_footprints,
		tile_width,
		tile_height,
		Vector2(600, 130)
	)
# =========================================
# TILE SELECTION
# =========================================

func _input(event):
	if building_interaction_controller != null:
		building_interaction_controller.handle_input(
			event,
			self
		)

func _buy_selected_land():
	var grid_pos = Vector2(selected_x, selected_y)
	var city_center = Vector2(0, 0)
	var road_system = get_node_or_null("../RoadSystem")

	if road_system == null:
		push_error("RoadSystem node NOT FOUND")
		return

	var start_x = int(floor(grid_pos.x / 2.0)) * 2
	var start_y = int(floor(grid_pos.y / 2.0)) * 2

	var total_price = 0
	var tiles_to_buy = 0

	for x in range(start_x, start_x + 2):
		for y in range(start_y, start_y + 2):
			var tile = Vector2(x, y)

			if not land_system.is_inside_map(tile):
				print("LAND PURCHASE FAILED: AREA_OUTSIDE_MAP")
				return

			if not land_system.is_owned(tile):
				total_price += land_system.get_land_price(
					tile,
					city_center,
					road_system
				)
				tiles_to_buy += 1

	if tiles_to_buy == 0:
		print("LAND PURCHASE FAILED: AREA_ALREADY_OWNED")
		return

	if not city_treasury.can_afford(total_price):
		print(
			"NOT ENOUGH MONEY. Price: ",
			total_price,
			" | Balance: ",
			city_treasury.get_balance()
		)
		return

	pending_land_grid = grid_pos

	land_purchase_dialog.dialog_text = (
		"Buy land in this 5x5 area?\n"
		+ "Tiles to buy: " + str(tiles_to_buy) + "\n"
		+ "Total price: $" + str(total_price) + "\n"
		+ "Current treasury: $" + str(city_treasury.get_balance())
	)

	land_purchase_dialog.popup_centered()


func _confirm_land_purchase():
	var road_system = get_node_or_null("../RoadSystem")

	if road_system == null:
		push_error("RoadSystem node NOT FOUND")
		return

	var result = land_purchase.purchase_area(
		pending_land_grid,
		Vector2(0, 0),
		land_system,
		city_treasury,
		road_system
	)

	if result["success"]:
		print(
			"LAND PURCHASED. Tiles: ",
			result["tiles_bought"],
			" | Price: $",
			result["price"],
			" | Remaining: $",
			result["balance"]
		)
		_update_treasury_label()
		update()
	else:
		print("LAND PURCHASE FAILED: ", result["error"])


func _update_treasury_label():
	if treasury_label != null:
		treasury_label.text = (
			"Municipal Treasury: $"
			+ str(city_treasury.get_balance())
		)
		# =========================================
# BUILDING ACTIONS
# =========================================

func _on_BuildingActionMenu_id_pressed(id):
	if selected_building_index < 0:
		return

	if selected_building_index >= placed_buildings.size():
		return

	match id:
		1:
			var building = placed_buildings[selected_building_index]
			var building_name = building_names.get(
				building["id"],
				building["id"]
			)

			print(
				"BUILDING INFO: ",
				building_name,
				" | Location: ",
				building["grid"]
			)

		2:
			moving_building_index = selected_building_index
			moving_building_origin = placed_buildings[
				moving_building_index
			]["grid"]

			print(
				"MOVE MODE STARTED: ",
				placed_buildings[moving_building_index]["id"],
				" | Click the destination tile."
			)

		3:
			pending_demolition_index = selected_building_index

			var building = placed_buildings[
				pending_demolition_index
			]

			building_action_dialog.dialog_text = (
				"Demolish "
				+ building_names.get(
					building["id"],
					building["id"]
				)
				+ "?"
			)

			building_action_dialog.popup_centered()

		4:
			building_action_menu.hide()


func _confirm_building_demolition():
	if pending_demolition_index < 0:
		return

	var result = building_actions.demolish_building(
		pending_demolition_index,
		placed_buildings
	)

	if not result["success"]:
		print("DEMOLITION FAILED: ", result["error"])
		pending_demolition_index = -1
		return

	print(
		"BUILDING DEMOLISHED: ",
		result["building"]["id"]
	)

	selected_building_index = -1
	pending_demolition_index = -1
	moving_building_index = -1

	building_visibility.clear_selection()

	if building_system != null:
		building_system.set_buildings(placed_buildings)

	_refresh_building_visuals()
	update()
