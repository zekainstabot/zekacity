
extends Node

# Building categories
const CATEGORY_RESIDENTIAL = "Residential"
const CATEGORY_ROADS = "Roads"
const CATEGORY_BUSINESS = "Businesses"
const CATEGORY_UTILITIES = "Utilities"
const CATEGORY_PUBLIC = "Public Services"
const CATEGORY_RECREATION = "Recreation"
const CATEGORY_ADVANCED = "Advanced"
const CATEGORY_WAREHOUSES = "Warehouses"

# Single source of truth for grid dimensions. Values are [width, height].
# Add a new building's footprint here; all placement and construction UI
# systems read the same dimensions through BuildingFootprints.gd.
const BUILDING_LAYOUTS = {
	"small_house": [1, 1],
	"normal_house": [2, 2],
	"low_apartment": [2, 2],
	"high_apartment": [3, 2],
	"residential_tower": [3, 3],
	"grocery_store": [2, 2],
	"bakery": [2, 2],
	"restaurant": [2, 2],
	"office": [2, 2],
	"shopping_mall": [4, 3],
	"factory": [3, 3],
	"mineral_market": [2, 2],
	"woodcutter": [2, 2],
	"sawmill": [3, 2],
	"carpenter": [2, 2],
	"water_tower": [2, 2],
	"power_station": [3, 3],
	"sewage_plant": [3, 3],
	"waste_facility": [3, 3],
	"school": [3, 2],
	"university": [4, 3],
	"clinic": [2, 2],
	"hospital": [3, 3],
	"police_station": [2, 2],
	"fire_station": [2, 2],
	"city_hall": [3, 3],
	"small_warehouse": [2, 2],
	"medium_warehouse": [3, 2],
	"large_warehouse": [3, 3],
	"huge_warehouse": [4, 3],
	"small_park": [2, 2],
	"playground": [2, 2],
	"sports_center": [3, 3],
	"cultural_center": [3, 2]
}


# Building definitions
const BUILDINGS = {
	"small_house": {
		"name": "Small House",
		"category": CATEGORY_RESIDENTIAL,
		"stage": 1,
		"population_required": 0,
		"cost": 100
	},
	"normal_house": {
		"name": "House",
		"category": CATEGORY_RESIDENTIAL,
		"stage": 2,
		"population_required": 5,
		"cost": 250
	},
	"low_apartment": {
		"name": "Low-rise Apartments",
		"category": CATEGORY_RESIDENTIAL,
		"stage": 3,
		"population_required": 20,
		"cost": 800
	},
	"high_apartment": {
		"name": "High-rise Apartments",
		"category": CATEGORY_RESIDENTIAL,
		"stage": 4,
		"population_required": 100,
		"cost": 3000
	},
	"residential_tower": {
		"name": "Residential Tower",
		"category": CATEGORY_ADVANCED,
		"stage": 5,
		"population_required": 500,
		"cost": 10000
	},

	"road": {
		"name": "Road",
		"category": CATEGORY_ROADS,
		"stage": 1,
		"population_required": 0,
		"cost": 20
	},

	"grocery_store": {
		"name": "Grocery Store",
		"category": CATEGORY_BUSINESS,
		"stage": 2,
		"population_required": 5,
		"cost": 300
	},
	"bakery": {
		"name": "Bakery",
		"category": CATEGORY_BUSINESS,
		"stage": 2,
		"population_required": 10,
		"cost": 400
	},
	"restaurant": {
		"name": "Restaurant",
		"category": CATEGORY_BUSINESS,
		"stage": 3,
		"population_required": 25,
		"cost": 1000
	},
	"office": {
		"name": "Office Building",
		"category": CATEGORY_BUSINESS,
		"stage": 3,
		"population_required": 40,
		"cost": 1800
	},
	"mineral_market": {
		"name": "Mineral Market",
		"category": CATEGORY_BUSINESS,
		"stage": 1,
		"population_required": 0,
		"cost": 500
	},
	"shopping_mall": {
		"name": "Shopping Mall",
		"category": CATEGORY_ADVANCED,
		"stage": 4,
		"population_required": 150,
		"cost": 8000
	},
	"factory": {
		"name": "Factory",
		"category": CATEGORY_ADVANCED,
		"stage": 4,
		"population_required": 100,
		"cost": 6000
	},

	"woodcutter": {
		"name": "Woodcutter",
		"category": CATEGORY_BUSINESS,
		"stage": 2,
		"population_required": 8,
		"cost": 900
	},
	"sawmill": {
		"name": "Sawmill",
		"category": CATEGORY_BUSINESS,
		"stage": 3,
		"population_required": 20,
		"cost": 1800
	},
	"carpenter": {
		"name": "Carpentry Workshop",
		"category": CATEGORY_BUSINESS,
		"stage": 3,
		"population_required": 35,
		"cost": 2600
	},

	"water_tower": {
		"name": "Water Tower",
		"category": CATEGORY_UTILITIES,
		"stage": 2,
		"population_required": 5,
		"cost": 500
	},
	"power_station": {
		"name": "Power Station",
		"category": CATEGORY_UTILITIES,
		"stage": 2,
		"population_required": 10,
		"cost": 1000
	},
	"sewage_plant": {
		"name": "Sewage Plant",
		"category": CATEGORY_UTILITIES,
		"stage": 3,
		"population_required": 25,
		"cost": 1800
	},
	"waste_facility": {
		"name": "Waste Facility",
		"category": CATEGORY_UTILITIES,
		"stage": 3,
		"population_required": 30,
		"cost": 1500
	},

	"school": {
		"name": "Elementary School",
		"category": CATEGORY_PUBLIC,
		"stage": 3,
		"population_required": 20,
		"cost": 1200
	},
	"clinic": {
		"name": "Clinic",
		"category": CATEGORY_PUBLIC,
		"stage": 3,
		"population_required": 25,
		"cost": 1400
	},
	"hospital": {
		"name": "Hospital",
		"category": CATEGORY_PUBLIC,
		"stage": 4,
		"population_required": 100,
		"cost": 5000
	},
	"police_station": {
		"name": "Police Station",
		"category": CATEGORY_PUBLIC,
		"stage": 4,
		"population_required": 80,
		"cost": 2500
	},
	"fire_station": {
		"name": "Fire Station",
		"category": CATEGORY_PUBLIC,
		"stage": 4,
		"population_required": 80,
		"cost": 2500
	},
	"city_hall": {
		"name": "City Hall",
		"category": CATEGORY_PUBLIC,
		"stage": 1,
		"population_required": 0,
		"cost": 0
	},

	"small_park": {
		"name": "Small Park",
		"category": CATEGORY_RECREATION,
		"stage": 2,
		"population_required": 10,
		"cost": 250
	},
	"playground": {
		"name": "Playground",
		"category": CATEGORY_RECREATION,
		"stage": 2,
		"population_required": 15,
		"cost": 350
	},
	"sports_center": {
		"name": "Sports Center",
		"category": CATEGORY_RECREATION,
		"stage": 4,
		"population_required": 100,
		"cost": 2500
	},
	"university": {
		"name": "University",
		"category": CATEGORY_PUBLIC,
		"stage": 4,
		"population_required": 150,
		"cost": 6000
	},
	"cultural_center": {
		"name": "Cultural Center",
		"category": CATEGORY_ADVANCED,
		"stage": 5,
		"population_required": 300,
		"cost": 4500
	},

	# Warehouses
	"small_warehouse": {
		"name": "Small Warehouse",
		"category": CATEGORY_WAREHOUSES,
		"stage": 1,
		"population_required": 0,
		"cost": 500
	},
	"medium_warehouse": {
		"name": "Medium Warehouse",
		"category": CATEGORY_WAREHOUSES,
		"stage": 1,
		"population_required": 0,
		"cost": 2000
	},
	"large_warehouse": {
		"name": "Large Warehouse",
		"category": CATEGORY_WAREHOUSES,
		"stage": 1,
		"population_required": 0,
		"cost": 6000
	},
	"huge_warehouse": {
		"name": "Huge Warehouse",
		"category": CATEGORY_WAREHOUSES,
		"stage": 1,
		"population_required": 0,
		"cost": 20000
	}
}


func get_building(building_id):
	if BUILDINGS.has(building_id):
		return BUILDINGS[building_id]

	return {}


func get_all_buildings():
	return BUILDINGS


func is_unlocked(building_id, population):
	if not BUILDINGS.has(building_id):
		return false

	var building = BUILDINGS[building_id]

	return population >= building["population_required"]


func get_buildings_by_category(category, population):
	var result = []

	for building_id in BUILDINGS.keys():
		var building = BUILDINGS[building_id]

		if building["category"] == category:
			if is_unlocked(building_id, population):
				result.append({
					"id": building_id,
					"data": building
				})

	return result
