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

	if ui != null:
		treasury_label = Label.new()
		treasury_label.name = "MoneyLabel"
		treasury_label.text = "Money: $" + str(city_treasury.get_balance())
		treasury_label.anchor_left = 1.0
		treasury_label.anchor_right = 1.0
		treasury_label.margin_left = -380
		treasury_label.margin_right = -20
		treasury_label.margin_top = 15
		treasury_label.margin_bottom = 75
		treasury_label.align = Label.ALIGN_LEFT
		treasury_label.valign = Label.VALIGN_CENTER
		treasury_label.set("custom_fonts/font", null)
		treasury_label.add_color_override(
			"font_color",
			Color(1, 1, 0.3, 1)
		)
		treasury_label.visible = true
		ui.add_child(treasury_label)
		treasury_label.raise()
		_update_treasury_label()

		buy_land_button = Button.new()
		buy_land_button.flat = true
		buy_land_button.name = "BuyLandButton"
		buy_land_button.text = ""
		buy_land_button.icon = load("res://land.png")
		buy_land_button.expand_icon = false
		buy_land_button.rect_min_size = Vector2(76, 76)
		buy_land_button.visible = false
		buy_land_button.anchor_left = 1.0
		buy_land_button.anchor_right = 1.0
		buy_land_button.margin_left = -185
		buy_land_button.margin_right = -32
		buy_land_button.margin_top = 55
		buy_land_button.margin_bottom = 119
		ui.add_child(buy_land_button)
		buy_land_button.connect(
			"pressed",
			self,
			"_buy_selected_land"
		)
	else:
		push_error("UI node NOT FOUND")

	land_purchase_dialog = ConfirmationDialog.new()
	land_purchase_dialog.name = "LandPurchaseDialog"

	if ui != null:
		ui.add_child(land_purchase_dialog)
	else:
		add_child(land_purchase_dialog)
		push_error("Land purchase dialog attached to World because UI was not found")

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

	update()
	
	var save_loaded = save_system.load_world(self)

	if not save_loaded:
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

func _on_BuildHouseButton_pressed():
	construction_menu_controller.on_build_button_pressed()


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

	var building_cost = 0

	# Only warehouses have a cost defined in StorageDefinitions.
	if StorageDefinitions.has_warehouse(building_id):
		building_cost = StorageDefinitions.get_cost(building_id)

		if building_cost < 0:
			print("BUILDING PLACEMENT FAILED: INVALID_WAREHOUSE")
			return false

		if not city_treasury.can_afford(building_cost):
			print(
				"NOT ENOUGH MONEY. Cost: $",
				building_cost,
				" | Balance: $",
				city_treasury.get_balance()
			)
			return false

		if not city_treasury.spend(building_cost):
			print("BUILDING PLACEMENT FAILED: PAYMENT_FAILED")
			return false
			
		if building_id == "mineral_market":
			building_cost = 500

		if not city_treasury.can_afford(building_cost):
			print(
				"NOT ENOUGH MONEY FOR MINERAL MARKET. Cost: $",
				building_cost,
				" | Balance: $",
				city_treasury.get_balance()
			)
			return false

		if not city_treasury.spend(building_cost):
			print("MINERAL MARKET PLACEMENT FAILED: PAYMENT_FAILED")
			return false

	# IMPORTANT: Add every building, not just warehouses.
	placed_buildings.append({
		"grid": grid_pos,
		"id": building_id
	})

	if building_system != null:
		building_system.set_buildings(placed_buildings)

	# Refresh shared storage capacity after building placement.
	storage_system.sync_warehouses(placed_buildings)

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

						# Ignore tiles outside the map when buying land near an edge.
			if not land_system.is_inside_map(tile):
				continue
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
			" | Balance: $",
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
			" | Price: ",
			result["price"],
			" | Remaining: $",
			result["balance"]
		)
		_update_treasury_label()

	if buy_land_button != null:
		buy_land_button.visible = false
		update()
	else:
		print("LAND PURCHASE FAILED: ", result["error"])


func _update_treasury_label():
	if treasury_label != null:
		treasury_label.text = "Money: $" + str(city_treasury.get_balance())

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

	_refresh_building_visuals()
	update()
	
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
