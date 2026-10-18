
extends Reference

# ZekaCity - SaveSystem.gd
# Godot 3.6
# ذخیره و بارگذاری پیشرفت شهر

const SAVE_PATH = "user://zeka_city_save.json"
const SAVE_VERSION = 1


func save_world(world):
	if world == null:
		return false

	var data = {
		"version": SAVE_VERSION,
		"grid_size": world.grid_size,
		"placed_buildings": [],
		"owned_tiles": [],
		"treasury": {},
		"resources": {},
		"roads": [],
		"mountains": [],
		"mines": []
	}

	# ساختمان‌ها
	for building in world.placed_buildings:
		data["placed_buildings"].append({
			"id": str(building.get("id", "")),
			"grid": _vector_to_data(
				building.get("grid", Vector2.ZERO)
			)
		})

	# زمین‌های خریداری‌شده
	for tile in world.land_system.owned_tiles:
		data["owned_tiles"].append(
			_vector_to_data(tile)
		)

	# خزانه شهرداری
	var treasury = world.city_treasury

	data["treasury"] = {
		"balance": treasury.balance,
		"locked_money": treasury.locked_money,
		"central_bank_built": treasury.central_bank_built,
		"central_bank_rebuild_days_left": (
			treasury.central_bank_rebuild_days_left
		),
		"municipal_banks": treasury.municipal_banks.duplicate(true)
	}

	# منابع
	data["resources"] = (
		world.resource_manager.get_all_amounts()
	)

	# جاده‌ها
	var road_system = world.get_node_or_null("../RoadSystem")

	if road_system != null:
		for road in road_system.roads:
			data["roads"].append({
				"grid": _vector_to_data(road["grid"]),
				"direction": int(road["direction"])
			})

	# کوه‌ها و معدن‌ها
	var mountain_system = world.get_node_or_null(
		"../MountainSystem"
	)

	if mountain_system != null:
		for mountain_id in mountain_system.mountains.keys():
			var mountain = mountain_system.mountains[mountain_id]

			data["mountains"].append({
				"id": str(mountain_id),
				"resource_id": str(mountain["resource_id"]),
				"origin": _vector_to_data(mountain["origin"]),
				"mine_point": _vector_to_data(
					mountain["mine_point"]
				),
				"mine_built": bool(mountain["mine_built"])
			})

		if mountain_system.mine_system != null:
			for mine_id in mountain_system.mine_system.mines.keys():
				var mine = mountain_system.mine_system.mines[mine_id]

				data["mines"].append({
					"id": str(mine_id),
					"resource_id": str(mine["resource_id"]),
					"active": bool(mine["active"]),
					"remaining": int(mine["remaining"]),
					"initial_reserve": int(mine["initial_reserve"]),
					"extracted": int(mine["extracted"]),
					"elapsed": float(mine["elapsed"])
				})

	var file = File.new()
	var error = file.open(SAVE_PATH, File.WRITE)

	if error != OK:
		push_error("SaveSystem: Could not open save file")
		return false

	file.store_string(to_json(data))
	file.close()

	print("CITY SAVED SUCCESSFULLY")
	return true


func load_world(world):
	if world == null:
		return false

	var file = File.new()

	if not file.file_exists(SAVE_PATH):
		print("SaveSystem: No previous save found")
		return false

	if file.open(SAVE_PATH, File.READ) != OK:
		push_error("SaveSystem: Could not read save file")
		return false

	var text = file.get_as_text()
	file.close()

	var data = parse_json(text)

	if typeof(data) != TYPE_DICTIONARY:
		push_error("SaveSystem: Save file is invalid")
		return false

	if int(data.get("version", 0)) != SAVE_VERSION:
		push_error("SaveSystem: Unsupported save version")
		return false

	# ساختمان‌ها
	world.placed_buildings.clear()

	for building in data.get("placed_buildings", []):
		world.placed_buildings.append({
			"id": str(building.get("id", "")),
			"grid": _data_to_vector(
				building.get("grid", {})
			)
		})

	# زمین‌ها
	world.land_system.owned_tiles.clear()

	for tile in data.get("owned_tiles", []):
		world.land_system.owned_tiles.append(
			_data_to_vector(tile)
		)

	# خزانه شهرداری
	var treasury_data = data.get("treasury", {})
	var treasury = world.city_treasury

	treasury.balance = int(
		treasury_data.get("balance", treasury.starting_money)
	)
	treasury.locked_money = int(
		treasury_data.get("locked_money", 0)
	)
	treasury.central_bank_built = bool(
		treasury_data.get("central_bank_built", false)
	)
	treasury.central_bank_rebuild_days_left = int(
		treasury_data.get("central_bank_rebuild_days_left", 0)
	)
	treasury.municipal_banks = treasury_data.get(
		"municipal_banks", []
	).duplicate(true)

	# منابع
	var saved_resources = data.get("resources", {})

	for resource_id in world.resource_manager.amounts.keys():
		if saved_resources.has(resource_id):
			world.resource_manager.amounts[resource_id] = int(
				saved_resources[resource_id]
			)

	# جاده‌ها
	var road_system = world.get_node_or_null("../RoadSystem")

	if road_system != null:
		road_system.roads.clear()

		for road in data.get("roads", []):
			road_system.roads.append({
				"grid": _data_to_vector(road.get("grid", {})),
				"direction": int(road.get("direction", 0))
			})

		road_system.update()

	# کوه‌ها و معدن‌ها
	var mountain_system = world.get_node_or_null(
		"../MountainSystem"
	)

	if mountain_system != null:
		mountain_system.mountains.clear()

		for mountain in data.get("mountains", []):
			var mountain_id = str(mountain.get("id", ""))

			mountain_system.mountains[mountain_id] = {
				"resource_id": str(
					mountain.get("resource_id", "")
				),
				"origin": _data_to_vector(
					mountain.get("origin", {})
				),
				"mine_point": _data_to_vector(
					mountain.get("mine_point", {})
				),
				"mine_built": bool(
					mountain.get("mine_built", false)
				)
			}

		if mountain_system.mine_system != null:
			mountain_system.mine_system.mines.clear()

			for mine in data.get("mines", []):
				var mine_id = str(mine.get("id", ""))

				mountain_system.mine_system.mines[mine_id] = {
					"resource_id": str(
						mine.get("resource_id", "")
					),
					"active": bool(mine.get("active", false)),
					"remaining": int(mine.get("remaining", 0)),
					"initial_reserve": int(
						mine.get("initial_reserve", 0)
					),
					"extracted": int(mine.get("extracted", 0)),
					"elapsed": float(mine.get("elapsed", 0.0))
				}

		mountain_system.update()

	# بازسازی وضعیت بصری و ظرفیت انبارها
	world.storage_system.sync_warehouses(
		world.placed_buildings
	)

	if world.building_system != null:
		world.building_system.set_buildings(
			world.placed_buildings
		)

	world._refresh_building_visuals()
	world._update_treasury_label()
	world.update()

	print("CITY LOADED SUCCESSFULLY")
	return true


func _vector_to_data(value):
	return {
		"x": float(value.x),
		"y": float(value.y)
	}


func _data_to_vector(value):
	if typeof(value) != TYPE_DICTIONARY:
		return Vector2.ZERO

	return Vector2(
		float(value.get("x", 0)),
		float(value.get("y", 0))
	)
