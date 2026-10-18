
extends Node

# Building categories
const CATEGORY_RESIDENTIAL = "Residential"
const CATEGORY_ROADS = "Roads"
const CATEGORY_BUSINESS = "Businesses"
const CATEGORY_UTILITIES = "Utilities"
const CATEGORY_PUBLIC = "Public Services"
const CATEGORY_RECREATION = "Recreation"
const CATEGORY_ADVANCED = "Advanced"

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
