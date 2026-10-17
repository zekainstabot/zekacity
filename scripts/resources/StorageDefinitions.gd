extends Reference

# ZekaCity - StorageDefinitions.gd
# Godot 3.6
# تعاریف انواع انبارها

const WAREHOUSES = {
	"small_warehouse": {
		"name": "Small Warehouse",
		"capacity": 100,
		"cost": 500,
		"footprint": Vector2(2, 2)
	},
	"medium_warehouse": {
		"name": "Medium Warehouse",
		"capacity": 500,
		"cost": 2000,
		"footprint": Vector2(3, 2)
	},
	"large_warehouse": {
		"name": "Large Warehouse",
		"capacity": 2000,
		"cost": 6000,
		"footprint": Vector2(3, 3)
	},
	"huge_warehouse": {
		"name": "Huge Warehouse",
		"capacity": 10000,
		"cost": 20000,
		"footprint": Vector2(4, 3)
	}
}


static func has_warehouse(warehouse_id):
	return WAREHOUSES.has(warehouse_id)


static func get_definition(warehouse_id):
	if not WAREHOUSES.has(warehouse_id):
		return {}

	return WAREHOUSES[warehouse_id].duplicate(true)


static func get_capacity(warehouse_id):
	if not WAREHOUSES.has(warehouse_id):
		return 0

	return int(WAREHOUSES[warehouse_id]["capacity"])


static func get_cost(warehouse_id):
	if not WAREHOUSES.has(warehouse_id):
		return -1

	return int(WAREHOUSES[warehouse_id]["cost"])


static func get_name(warehouse_id):
	if not WAREHOUSES.has(warehouse_id):
		return ""

	return str(WAREHOUSES[warehouse_id]["name"])


static func get_footprint(warehouse_id):
	if not WAREHOUSES.has(warehouse_id):
		return Vector2(1, 1)

	return WAREHOUSES[warehouse_id]["footprint"]
