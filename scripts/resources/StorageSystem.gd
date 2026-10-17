extends Reference

# ZekaCity - StorageSystem.gd
# Godot 3.6
# مدیریت ظرفیت مشترک تمام انبارهای شهر

const StorageDefinitions = preload(
	"res://scripts/resources/StorageDefinitions.gd"
)

var warehouses = {}


func register_warehouse(building_key, warehouse_id):
	if warehouses.has(building_key):
		return false

	if not StorageDefinitions.has_warehouse(warehouse_id):
		return false

	warehouses[building_key] = {
		"id": warehouse_id,
		"capacity": StorageDefinitions.get_capacity(warehouse_id)
	}

	return true


func unregister_warehouse(building_key):
	if not warehouses.has(building_key):
		return false

	warehouses.erase(building_key)
	return true


func sync_warehouses(placed_buildings):
	var active_warehouses = {}

	for building in placed_buildings:
		var building_id = str(building.get("id", ""))

		if not StorageDefinitions.has_warehouse(building_id):
			continue

		var grid_pos = building.get("grid", Vector2.ZERO)
		var building_key = str(grid_pos)

		active_warehouses[building_key] = building_id

	for building_key in warehouses.keys().duplicate():
		if not active_warehouses.has(building_key):
			warehouses.erase(building_key)

	for building_key in active_warehouses.keys():
		var warehouse_id = active_warehouses[building_key]

		if warehouses.has(building_key):
			if str(warehouses[building_key]["id"]) == warehouse_id:
				continue

			warehouses.erase(building_key)

		register_warehouse(building_key, warehouse_id)


func get_warehouse_count():
	return warehouses.size()


func get_total_capacity():
	var total = 0

	for building_key in warehouses.keys():
		total += int(warehouses[building_key]["capacity"])

	return total


func get_used_capacity(resource_manager):
	if resource_manager == null:
		return 0

	var amounts = resource_manager.get_all_amounts()
	var total = 0

	for resource_id in amounts.keys():
		total += max(0, int(amounts[resource_id]))

	return total


func get_free_capacity(resource_manager):
	return max(
		0,
		get_total_capacity() - get_used_capacity(resource_manager)
	)


func can_store(resource_manager, amount = 1):
	if amount <= 0:
		return false

	return get_free_capacity(resource_manager) >= amount


func get_warehouse(building_key):
	if not warehouses.has(building_key):
		return {}

	return warehouses[building_key].duplicate(true)


func get_all_warehouses():
	return warehouses.duplicate(true)
