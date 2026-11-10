extends Reference

# ZekaCity - SaveSystem.gd
# Godot 3.6
# ذخیره و بارگذاری پیشرفت شهر

const SAVE_PATH = "user://zeka_city_save.json"
const TEMP_SAVE_PATH = "user://zeka_city_save.tmp"
const BACKUP_SAVE_PATH = "user://zeka_city_save.backup.json"
const SAVE_VERSION = 1


func save_world(world):
	if world == null:
		return false

	var data = {
		"version": SAVE_VERSION,
		"grid_size": world.grid_size,
		"player_money": int(world.player_money),
		"placed_buildings": [],
		"owned_tiles": [],
		"treasury": {},
		"resources": {},
		"mineral_market": {},
		"mineral_market_sale_accumulators": {},
		"roads": [],
		"mountains": [],
		"forests": [],
		"mines": [],
		"citizens": []
	}

	# ساختمان‌ها و حساب کسب‌وکار
	for building in world.placed_buildings:
		data["placed_buildings"].append({
			"id": str(building.get("id", "")),
			"grid": _vector_to_data(
				building.get("grid", Vector2.ZERO)
			),
			"owner_type": str(
				building.get("owner_type", "player")
			),
			"owner_id": str(
				building.get("owner_id", "player")
			),
			"business_balance": int(
				building.get("business_balance", 0)
			),
			"unpaid_wages": int(
				building.get("unpaid_wages", 0)
			),
			"last_revenue": int(
				building.get("last_revenue", 0)
			),
			"last_wages": int(
				building.get("last_wages", 0)
			),
			"last_profit": int(
				building.get("last_profit", 0)
			),
			"total_revenue": int(
				building.get("total_revenue", 0)
			),
			"total_wages": int(
				building.get("total_wages", 0)
			),
			"total_profit": int(
				building.get("total_profit", 0)
			)
		})

	# زمین‌های خریداری‌شده
	if world.land_system != null:
		for tile in world.land_system.owned_tiles:
			data["owned_tiles"].append(
				_vector_to_data(tile)
			)

	# خزانه شهرداری
	var treasury = world.city_treasury

	if treasury != null:
		data["treasury"] = {
			"balance": treasury.balance,
			"locked_money": treasury.locked_money,
			"central_bank_built": treasury.central_bank_built,
			"central_bank_rebuild_days_left": (
				treasury.central_bank_rebuild_days_left
			),
			"municipal_banks": (
				treasury.municipal_banks.duplicate(true)
			)
		}

	# منابع شهرداری
	if world.resource_manager != null:
		data["resources"] = (
			world.resource_manager.get_all_amounts()
		)

	# موجودی و زمان‌بندی فروش خودکار بازار مواد معدنی
	var market = world.get("mineral_market_system")

	if market != null:
		data["mineral_market"] = market.get_stock_data()
		data["mineral_market_sale_accumulators"] = (
			market.sale_accumulators.duplicate(true)
		)

	# جاده‌ها
	# ساختار جدید: هر جاده فقط یک grid دارد.
	var road_system = world.get_node_or_null("../RoadSystem")

	if road_system != null:
		for road in road_system.roads:
			if typeof(road) != TYPE_DICTIONARY:
				continue

			data["roads"].append({
				"grid": _vector_to_data(
					road.get("grid", Vector2.ZERO)
				)
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
				"resource_id": str(
					mountain.get("resource_id", "")
				),
				"origin": _vector_to_data(
					mountain.get("origin", Vector2.ZERO)
				),
				"mine_point": _vector_to_data(
					mountain.get("mine_point", Vector2.ZERO)
				),
				"mine_built": bool(
					mountain.get("mine_built", false)
				)
			})

		if mountain_system.mine_system != null:
			for mine_id in mountain_system.mine_system.mines.keys():
				var mine = mountain_system.mine_system.mines[mine_id]

				data["mines"].append({
					"id": str(mine_id),
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
				})

	# Forest trees
	var forest_system = world.get_node_or_null("../ForestSystem")
	if forest_system != null:
		data["forests"] = forest_system.get_save_data()

	# شهروندها
	if world.citizen_system != null:
		data["citizens"] = world.citizen_system.get_save_data()

	# نوشتن امن: ابتدا فایل موقت ساخته و بررسی می‌شود.
	# فایل ذخیره قبلی تا موفقیت کامل نوشتن حفظ خواهد شد.
	if not _write_save_file_atomic(data):
		push_error("SaveSystem: Atomic save failed; previous save was preserved")
		return false

	print("CITY SAVED SUCCESSFULLY")
	return true


func load_world(world):
	if world == null:
		return false

	var data = _read_valid_save(SAVE_PATH)

	if data.empty():
		push_warning("SaveSystem: Main save is invalid; trying backup")
		data = _read_valid_save(BACKUP_SAVE_PATH)

	if data.empty():
		var file_check = File.new()
		if file_check.file_exists(SAVE_PATH) or file_check.file_exists(BACKUP_SAVE_PATH):
			push_error("SaveSystem: No valid save or backup could be loaded")
		else:
			print("SaveSystem: No previous save found")
		return false

	# بازیابی پول شخصی بازیکن
	world.player_money = int(
		data.get("player_money", 1000)
	)

	# ساختمان‌ها و حساب‌های کسب‌وکار
	world.placed_buildings.clear()

	for building in data.get("placed_buildings", []):
		if typeof(building) != TYPE_DICTIONARY:
			continue

		world.placed_buildings.append({
			"id": str(building.get("id", "")),
			"grid": _data_to_vector(
				building.get("grid", {})
			),
			"owner_type": str(
				building.get("owner_type", "player")
			),
			"owner_id": str(
				building.get("owner_id", "player")
			),
			"business_balance": int(
				building.get("business_balance", 0)
			),
			"unpaid_wages": int(
				building.get("unpaid_wages", 0)
			),
			"last_revenue": int(
				building.get("last_revenue", 0)
			),
			"last_wages": int(
				building.get("last_wages", 0)
			),
			"last_profit": int(
				building.get("last_profit", 0)
			),
			"total_revenue": int(
				building.get("total_revenue", 0)
			),
			"total_wages": int(
				building.get("total_wages", 0)
			),
			"total_profit": int(
				building.get("total_profit", 0)
			)
		})

	# بازیابی شهروندها
	if world.citizen_system != null:
		var saved_citizens = data.get("citizens", [])

		if typeof(saved_citizens) == TYPE_ARRAY:
			world.citizen_system.load_data(saved_citizens)

	# زمین‌های خریداری‌شده
	if world.land_system != null:
		world.land_system.owned_tiles.clear()

		for tile in data.get("owned_tiles", []):
			world.land_system.owned_tiles.append(
				_data_to_vector(tile)
			)

	# خزانه شهرداری
	var treasury_data = data.get("treasury", {})
	var treasury = world.city_treasury

	if treasury != null and typeof(treasury_data) == TYPE_DICTIONARY:
		treasury.balance = int(
			treasury_data.get(
				"balance",
				treasury.starting_money
			)
		)

		treasury.locked_money = int(
			treasury_data.get("locked_money", 0)
		)

		treasury.central_bank_built = bool(
			treasury_data.get("central_bank_built", false)
		)

		treasury.central_bank_rebuild_days_left = int(
			treasury_data.get(
				"central_bank_rebuild_days_left",
				0
			)
		)

		var saved_banks = treasury_data.get(
			"municipal_banks", []
		)

		if typeof(saved_banks) == TYPE_ARRAY:
			treasury.municipal_banks = saved_banks.duplicate(true)

	# منابع شهرداری
	var saved_resources = data.get("resources", {})

	if world.resource_manager != null and typeof(saved_resources) == TYPE_DICTIONARY:
		for resource_id in world.resource_manager.amounts.keys():
			if saved_resources.has(resource_id):
				world.resource_manager.amounts[resource_id] = int(
					saved_resources[resource_id]
				)

	# بازیابی موجودی و زمان‌بندی فروش خودکار بازار مواد معدنی
	var market = world.get("mineral_market_system")

	if market != null:
		market.restore_stock(
			data.get("mineral_market", {})
		)

		var saved_accumulators = data.get(
			"mineral_market_sale_accumulators",
			{}
		)

		if typeof(saved_accumulators) == TYPE_DICTIONARY:
			for resource_id in market.sale_accumulators.keys():
				market.sale_accumulators[resource_id] = clamp(
					float(saved_accumulators.get(resource_id, 0.0)),
					0.0,
					0.999999
				)

	# جاده‌ها
	# direction ذخیره‌های قدیمی عمداً نادیده گرفته می‌شود.
	var road_system = world.get_node_or_null("../RoadSystem")

	if road_system != null:
		road_system.roads.clear()

		var saved_roads = data.get("roads", [])

		if typeof(saved_roads) == TYPE_ARRAY:
			for road in saved_roads:
				if typeof(road) != TYPE_DICTIONARY:
					continue

				road_system.roads.append({
					"grid": _data_to_vector(
						road.get("grid", {})
					)
				})

		# حذف جاده‌های تکراری و نرمال‌سازی ساختار
		if road_system.has_method("_normalize_roads"):
			road_system._normalize_roads()

		road_system.update()

	# کوه‌ها و معدن‌ها
	var mountain_system = world.get_node_or_null(
		"../MountainSystem"
	)

	if mountain_system != null:
		mountain_system.mountains.clear()

		var saved_mountains = data.get("mountains", [])

		if typeof(saved_mountains) == TYPE_ARRAY:
			for mountain in saved_mountains:
				if typeof(mountain) != TYPE_DICTIONARY:
					continue

				var mountain_id = str(
					mountain.get("id", "")
				)

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

			var saved_mines = data.get("mines", [])

			if typeof(saved_mines) == TYPE_ARRAY:
				for mine in saved_mines:
					if typeof(mine) != TYPE_DICTIONARY:
						continue

					var mine_id = str(
						mine.get("id", "")
					)

					mountain_system.mine_system.mines[mine_id] = {
						"resource_id": str(
							mine.get("resource_id", "")
						),
						"active": bool(mine.get("active", false)),
						"remaining": int(mine.get("remaining", 0)),
						"initial_reserve": int(
							mine.get("initial_reserve", 0)
						),
						"extracted": int(
							mine.get("extracted", 0)
						),
						"elapsed": float(
							mine.get("elapsed", 0.0)
						)
					}

		# Rebuild individual depth-sorted mountain visuals from the
		# restored save data (the initial random mountain layout is obsolete).
		mountain_system._refresh_mountain_visuals()
		mountain_system.update()

	# Restore the saved forest instead of generating a new tree layout.
	var forest_system = world.get_node_or_null("../ForestSystem")
	if forest_system != null and data.has("forests"):
		forest_system.load_data(data.get("forests", []))

	# بازسازی ظرفیت انبارها
	if world.storage_system != null:
		world.storage_system.sync_warehouses(
			world.placed_buildings
		)

	# بازسازی ساختمان‌ها
	if world.building_system != null:
		world.building_system.set_buildings(
			world.placed_buildings
		)

	# به‌روزرسانی نمایش شهر
	world._refresh_building_visuals()
	world._update_treasury_label()
	world.update()

	print("CITY LOADED SUCCESSFULLY")
	return true


# --------------------------------------------------
# SAFE SAVE / RECOVERY
# --------------------------------------------------

func _write_save_file_atomic(data):
	var file = File.new()
	var error = file.open(TEMP_SAVE_PATH, File.WRITE)

	if error != OK:
		push_error("SaveSystem: Could not open temporary save file: " + str(error))
		return false

	file.store_string(to_json(data))
	file.flush()
	var write_error = file.get_error()
	file.close()

	if write_error != OK:
		var cleanup = Directory.new()
		cleanup.remove(TEMP_SAVE_PATH)
		push_error("SaveSystem: Temporary save write failed: " + str(write_error))
		return false

	# Rotate the backup only when a main save exists. If the main file
	# is missing but a backup remains, never delete that last good copy.
	var directory = Directory.new()
	if directory.file_exists(SAVE_PATH):
		if directory.file_exists(BACKUP_SAVE_PATH):
			var remove_error = directory.remove(BACKUP_SAVE_PATH)
			if remove_error != OK:
				directory.remove(TEMP_SAVE_PATH)
				push_error("SaveSystem: Could not rotate backup: " + str(remove_error))
				return false

		var backup_error = directory.rename(SAVE_PATH, BACKUP_SAVE_PATH)
		if backup_error != OK:
			directory.remove(TEMP_SAVE_PATH)
			push_error("SaveSystem: Could not preserve previous save: " + str(backup_error))
			return false

	var replace_error = directory.rename(TEMP_SAVE_PATH, SAVE_PATH)
	if replace_error != OK:
		# Restore the previous save if the new file could not be installed.
		if directory.file_exists(BACKUP_SAVE_PATH) and not directory.file_exists(SAVE_PATH):
			directory.rename(BACKUP_SAVE_PATH, SAVE_PATH)

		directory.remove(TEMP_SAVE_PATH)
		push_error("SaveSystem: Could not install new save: " + str(replace_error))
		return false

	return true


func _read_valid_save(path):
	var file = File.new()

	if not file.file_exists(path):
		return {}

	if file.open(path, File.READ) != OK:
		return {}

	var save_text = file.get_as_text()
	file.close()

	var parsed = parse_json(save_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	if int(parsed.get("version", 0)) != SAVE_VERSION:
		return {}

	# Validate collection types before load_world mutates the running city.
	var array_fields = [
		"placed_buildings",
		"owned_tiles",
		"roads",
		"mountains",
		"forests",
		"mines",
		"citizens"
	]

	for field in array_fields:
		if parsed.has(field) and typeof(parsed[field]) != TYPE_ARRAY:
			return {}

	var dictionary_fields = [
		"treasury",
		"resources",
		"mineral_market",
		"mineral_market_sale_accumulators"
	]

	for field in dictionary_fields:
		if parsed.has(field) and typeof(parsed[field]) != TYPE_DICTIONARY:
			return {}

	if parsed.has("grid_size"):
		if int(parsed["grid_size"]) < 1:
			return {}

	# Reject structurally damaged records before they can be converted
	# into Vector2.ZERO and accidentally place data at the map origin.
	for building in parsed.get("placed_buildings", []):
		if typeof(building) != TYPE_DICTIONARY:
			return {}
		if str(building.get("id", "")).strip_edges() == "":
			return {}
		if not _is_valid_vector_data(building.get("grid", null)):
			return {}

	for tile in parsed.get("owned_tiles", []):
		if not _is_valid_vector_data(tile):
			return {}

	for road in parsed.get("roads", []):
		if typeof(road) != TYPE_DICTIONARY:
			return {}
		if not _is_valid_vector_data(road.get("grid", null)):
			return {}

	for tree in parsed.get("forests", []):
		if typeof(tree) != TYPE_DICTIONARY:
			return {}
		if not _is_valid_vector_data(tree.get("grid", null)):
			return {}

	for mountain in parsed.get("mountains", []):
		if typeof(mountain) != TYPE_DICTIONARY:
			return {}
		if str(mountain.get("id", "")).strip_edges() == "":
			return {}
		if not _is_valid_vector_data(mountain.get("origin", null)):
			return {}
		if not _is_valid_vector_data(mountain.get("mine_point", null)):
			return {}

	for mine in parsed.get("mines", []):
		if typeof(mine) != TYPE_DICTIONARY:
			return {}
		if str(mine.get("id", "")).strip_edges() == "":
			return {}

	for citizen in parsed.get("citizens", []):
		if typeof(citizen) != TYPE_DICTIONARY:
			return {}
		if str(citizen.get("id", "")).strip_edges() == "":
			return {}
		if not _is_valid_vector_data(citizen.get("home_grid", null)):
			return {}
		if not _is_valid_vector_data(citizen.get("grid_pos", null)):
			return {}
		for vector_field in ["target_grid", "previous_grid", "work_grid"]:
			if citizen.has(vector_field) and not _is_valid_vector_data(citizen[vector_field]):
				return {}

	return parsed


func _is_valid_vector_data(value):
	if typeof(value) != TYPE_DICTIONARY:
		return false

	if not value.has("x") or not value.has("y"):
		return false

	var x_type = typeof(value["x"])
	var y_type = typeof(value["y"])

	var numeric_types = [TYPE_INT, TYPE_REAL]
	return x_type in numeric_types and y_type in numeric_types


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
