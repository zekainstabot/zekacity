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
var road_placement_direction = -1
var selected_building_for_placement = ""

var placed_buildings = []
var building_system = null

var citizen_system = null

var save_system = preload(
	"res://scripts/SaveSystem.gd"
).new()

var autosave_elapsed = 0.0
var autosave_interval = 30.0

var storage_system = preload(
	"res://scripts/resources/StorageSystem.gd"
).new()

var resource_manager = preload(
	"res://scripts/resources/ResourceManager.gd"
).new()

var mineral_market_system = preload(
	"res://scripts/economy/MineralMarketSystem.gd"
).new()

var construction_menu_controller = preload(
	"res://scripts/buildings/ConstructionMenuController.gd"
).new()

var world_ui_controller = preload(
	"res://scripts/ui/WorldUIController.gd"
).new()

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

var residential_buildings = preload(
	"res://scripts/buildings/ResidentialBuildings.gd"
).new()

var commercial_buildings = preload(
	"res://scripts/buildings/CommercialBuildings.gd"
).new()

var warehouse_buildings = preload(
	"res://scripts/buildings/WarehouseBuildings.gd"
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

var land_purchase_controller = preload(
	"res://scripts/land/LandPurchaseController.gd"
).new()

var treasury_label = null
var land_purchase_dialog = null
var pending_land_grid = Vector2(0, 0)

var buy_land_button = null

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
	"mineral_market": "Mineral Market",
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
	"cultural_center": "Cultural Center",
	"small_warehouse": "Small Warehouse",
	"medium_warehouse": "Medium Warehouse",
	"large_warehouse": "Large Warehouse",
	"huge_warehouse": "Huge Warehouse"
}


# =========================================
# INITIALIZATION
# =========================================


func _ready():
	print("CITY TREASURY INITIALIZED: ", city_treasury.get_balance())

	var ui = get_node_or_null("../UI")

	if ui == null:
		ui = get_node_or_null("/root/main/UI")

	if ui == null:
		push_error("UI node NOT FOUND in World.gd")
		return

	var ui_elements = world_ui_controller.initialize(self, ui)
	print("DEBUG UI: ", ui)
	print("DEBUG MONEY LABEL: ", ui_elements.get("treasury_label"))

# بعد از آماده‌شدن UI، دکمه ساخت را تنظیم کن.
	_setup_construction_button()
	land_purchase_controller.initialize(self)

	treasury_label = ui_elements.get("treasury_label")
	buy_land_button = ui_elements.get("buy_land_button")
	land_purchase_dialog = ui_elements.get("land_purchase_dialog")

	if treasury_label != null:
		_update_treasury_label()

	land_system.initialize(grid_size)

	if placed_buildings.empty():
		placed_buildings.append({
			"grid": Vector2(0, 0),
			"id": "small_house"
		})

	resource_manager.set_storage_system(storage_system)
	storage_system.sync_warehouses(placed_buildings)

	var mountain_system = get_node_or_null("../MountainSystem")

	if mountain_system == null:
		push_error("MountainSystem node NOT FOUND")
	else:
		mountain_system.initialize(
			self,
			city_treasury,
			ui
		)

	submenu_menu = PopupMenu.new()
	submenu_menu.name = "BuildingSubmenu"
	submenu_menu.set_as_toplevel(true)
	add_child(submenu_menu)

	construction_menu_controller.initialize(
		self,
		submenu_menu
	)
	
	

	var construction_layer = CanvasLayer.new()
	construction_layer.name = "ConstructionLayer"
	construction_layer.layer = 10
	add_child(construction_layer)

	var construction_ui = load(
	"res://scripts/buildings/ConstructionUI.gd"
	).new()

	construction_ui.name = "ConstructionUI"
	construction_layer.add_child(construction_ui)


	construction_ui.connect(
		"building_confirmed",
		self,
		"_on_construction_ui_building_confirmed"
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

	building_action_panel.connect(
		"market_sell_requested",
		self,
		"_on_market_sell_requested"
	)

	building_action_dialog = ConfirmationDialog.new()
	building_action_dialog.name = "BuildingActionDialog"
	building_action_dialog.rect_min_size = Vector2(420, 200)
	add_child(building_action_dialog)

	building_action_dialog.connect(
		"confirmed",
		self,
		"_confirm_building_demolition"
	)

	
	citizen_system = load(
		"res://scripts/citizens/CitizenSystem.gd"
	).new()

	citizen_system.name = "CitizenSystem"
	add_child(citizen_system)
	citizen_system.initialize(self)

	update()

	var save_loaded = save_system.load_world(self)

	if not save_loaded:
		citizen_system.sync_residents()
		save_system.save_world(self)
	else:
		print("Previous city progress restored")


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
		"factory",
		"mineral_market"
	]:
		commercial_buildings.draw_building(
			self,
			building_id,
			pos
		)
		return

	if building_id in [
		"small_warehouse",
		"medium_warehouse",
		"large_warehouse",
		"huge_warehouse"
	]:
		warehouse_buildings.draw_building(
			self,
			building_id,
			pos
		)
		return

	if building_id in ["school", "university"]:
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
		return


# =========================================
# CONSTRUCTION MENU
# =========================================

func _on_ConstructionMenu_id_pressed(id):
	construction_menu_controller.on_category_selected(id)


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
		return false

	var StorageDefinitions = load(
		"res://scripts/resources/StorageDefinitions.gd"
	)
	var BuildingData = load(
		"res://scripts/BuildingData.gd"
	)

	var building_cost = 0

	if StorageDefinitions.has_warehouse(building_id):
		building_cost = int(
			StorageDefinitions.get_cost(building_id)
		)
	else:
		if not BuildingData.BUILDINGS.has(building_id):
			print(
				"BUILDING PLACEMENT FAILED: UNKNOWN_BUILDING_COST: ",
				building_id
			)
			return false

		building_cost = int(
			BuildingData.BUILDINGS[building_id].get("cost", 0)
		)

	if building_cost < 0:
		print("BUILDING PLACEMENT FAILED: INVALID_COST")
		return false

	if not city_treasury.can_afford(building_cost):
		print(
			"NOT ENOUGH MONEY. Cost: $",
			building_cost,
			" | Balance: $",
			city_treasury.get_balance()
		)
		return false

	if building_cost > 0:
		if not city_treasury.spend(building_cost):
			print("BUILDING PLACEMENT FAILED: PAYMENT_FAILED")
			return false

	placed_buildings.append({
		"grid": grid_pos,
		"id": building_id
	})

	if building_system != null:
		building_system.set_buildings(placed_buildings)

	storage_system.sync_warehouses(placed_buildings)
	
	
	if citizen_system != null:
		citizen_system.sync_residents()


	selected_building_for_placement = ""
	road_placement_direction = -1

	_refresh_building_visuals()
	_update_treasury_label()
	update()

	print(
		"BUILDING PLACED SUCCESSFULLY: ",
		building_id,
		" | ",
		grid_pos,
		" | Cost: $",
		building_cost
	)

	save_system.save_world(self)

	return true

# =========================================
# PLACING ROADS
# =========================================

func _place_road(direction):
	if direction != 0 and direction != 1:
		push_error("Invalid road direction: " + str(direction))
		return

	road_placement_direction = direction

	if direction == 0:
		print("ROAD A SELECTED: Click a tile to place the road.")
	else:
		print("ROAD B SELECTED: Click a tile to place the road.")


func _confirm_place_road():
	if road_placement_direction < 0:
		return

	var road_system = get_node_or_null("../RoadSystem")

	if road_system == null:
		push_error("RoadSystem node NOT FOUND")
		return

	var grid_pos = Vector2(selected_x, selected_y)

	if is_tile_occupied(grid_pos):
		print("Cannot build a road on a building tile: ", grid_pos)
		return

	var added = road_system.add_road(
		grid_pos,
		road_placement_direction
	)

	if added:
		print("ROAD PLACED SUCCESSFULLY: ", grid_pos)
		road_placement_direction = -1


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

func _unhandled_input(event):
	if building_interaction_controller != null:
		building_interaction_controller.handle_input(
			event,
			self
		)


# =========================================
# LAND PURCHASE
# =========================================


func _buy_selected_land():
	if land_purchase_controller != null:
		land_purchase_controller.request_selected_land()


func _confirm_land_purchase():
	if land_purchase_controller != null:
		land_purchase_controller.confirm_land_purchase()


func _update_treasury_label():
	if world_ui_controller != null:
		world_ui_controller.update_treasury_label()

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
			if building_action_menu != null:
				building_action_menu.hide()
				
func _on_market_sell_requested(resource_id, amount):
	if selected_building_index < 0:
		return

	if selected_building_index >= placed_buildings.size():
		return

	var building = placed_buildings[selected_building_index]

	if str(building.get("id", "")) != "mineral_market":
		return

	var result = mineral_market_system.receive_from_municipal_storage(
		resource_id,
		amount,
		resource_manager,
		city_treasury
	)

	if not result.get("success", false):
		print(
			"MARKET TRANSFER FAILED: ",
			result.get("error", "UNKNOWN_ERROR")
		)
		return

	print(
		"MARKET TRANSFER SUCCESS: ",
		result["amount"],
		" ",
		result["product"],
		" | Revenue: $",
		result["revenue"],
		" | Market stock: ",
		result["stock"]
	)

	_update_treasury_label()
	save_system.save_world(self)

	building_action_panel.show_for_building(
		"Mineral Market",
		self,
		"mineral_market"
	)

	update()


# =========================================
# BUILDING DEMOLITION
# =========================================

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
	moving_building_origin = Vector2(-1, -1)

	building_visibility.clear_selection()

	if building_action_panel != null:
		building_action_panel.hide_panel()

	if building_system != null:
		building_system.set_buildings(placed_buildings)

	# Keep shared warehouse capacity synchronized after demolition.
	storage_system.sync_warehouses(placed_buildings)
	
	
	if citizen_system != null:
		citizen_system.sync_residents()


	_refresh_building_visuals()
	_update_treasury_label()
	update()
	save_system.save_world(self)

	
func _process(delta):
	if save_system == null:
		return

	autosave_elapsed += delta

	if autosave_elapsed >= autosave_interval:
		autosave_elapsed = 0.0
		save_system.save_world(self)


func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		if save_system != null:
			save_system.save_world(self)




func _setup_construction_button():
	var ui = get_node_or_null("../UI")

	if ui == null:
		ui = get_node_or_null("/root/main/UI")

	if ui == null:
		push_error("UI node NOT FOUND")
		return

	var button = ui.get_node_or_null("ConstructionButton")

	if button == null:
		push_error("ConstructionButton NOT FOUND inside UI")
		return

	button.anchor_left = 1.0
	button.anchor_top = 1.0
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0

	button.margin_left = -124.0
	button.margin_top = -124.0
	button.margin_right = -20.0
	button.margin_bottom = -20.0

	button.rect_min_size = Vector2(104, 104)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.48, 0.78, 0.96)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24

	button.add_stylebox_override("normal", style)
	button.add_stylebox_override("hover", style)
	button.add_stylebox_override("pressed", style)

	var hammer_font = DynamicFont.new()
	var hammer_font_path = "res://assets/fonts/Roboto-Regular.ttf"
	if ResourceLoader.exists(hammer_font_path):
		hammer_font.font_data = load(hammer_font_path)
	hammer_font.size = 28
	button.add_font_override("font", hammer_font)

	if not button.is_connected(
		"pressed",
		self,
		"_on_BuildHouseButton_pressed"
	):
		button.connect(
			"pressed",
			self,
			"_on_BuildHouseButton_pressed"
		)


func _on_BuildHouseButton_pressed():
	var construction_ui = get_node_or_null(
		"ConstructionLayer/ConstructionUI"
	)

	if construction_ui != null:
		construction_ui.open_menu()
	else:
		push_error("ConstructionUI not found inside ConstructionLayer")



func _on_construction_ui_building_confirmed(building_id):
	if building_id == "stone_mine" or building_id == "iron_mine":
		selected_building_for_placement = ""
		road_placement_direction = -1

		var resource = "stone" if building_id == "stone_mine" else "iron_ore"
		set_meta("mine_placement_resource", resource)

		print("Mine selected: Click its mountain mining point.")
		return

	if has_meta("mine_placement_resource"):
		remove_meta("mine_placement_resource")

	selected_building_for_placement = building_id
	road_placement_direction = -1

	print(
		"BUILDING SELECTED: ",
		building_id,
		" | Tap a valid tile to place it."
	)
