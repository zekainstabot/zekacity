
extends Node2D

# ZekaCity - CitizenSystem.gd
# Godot 3.6

const CITIZEN_VISUAL_PATH = "res://scripts/citizens/CitizenVisual.gd"
const SHOP_INTERVAL = 30.0

const HOME_VISIT_INTERVAL_MIN = 35.0
const HOME_VISIT_INTERVAL_MAX = 60.0
const HOME_STAY_MIN = 10.0
const HOME_STAY_MAX = 20.0

const JOB_CAPACITY = {
	"grocery_store": 3,
	"bakery": 4,
	"restaurant": 6,
	"office": 20,
	"mineral_market": 1,
	"shopping_mall": 30,
	"factory": 25
}

var world = null
var citizens = []
var visuals = {}
var next_citizen_id = 1
var rng = RandomNumberGenerator.new()
var shopping_timer = 0.0


func initialize(world_node):
	world = world_node
	rng.randomize()
	set_process(true)


# --------------------------------------------------
# PROCESS
# --------------------------------------------------

func _process(delta):
	if world == null:
		return

	shopping_timer += delta

	if shopping_timer >= SHOP_INTERVAL:
		shopping_timer = 0.0
		_process_citizen_shopping()

	for citizen in citizens:
		_initialize_citizen_state(citizen)

		var citizen_id = str(citizen["id"])

		# Citizen is currently inside the home.
		if citizen["at_home"]:
			citizen["home_timer"] -= delta

			if citizen["home_timer"] <= 0.0:
				citizen["at_home"] = false
				citizen["returning_home"] = false
				citizen["home_visit_timer"] = rng.randf_range(
					HOME_VISIT_INTERVAL_MIN,
					HOME_VISIT_INTERVAL_MAX
				)

				if visuals.has(citizen_id):
					visuals[citizen_id].visible = true

				_choose_next_target(citizen)
				_update_citizen_visual(citizen)

			continue

		var current = citizen["grid_pos"]
		var target = citizen["target_grid"]

		# Citizen has reached the current target.
		if current == target:
			citizen["move_progress"] = 0.0

			if citizen["returning_home"]:
				_continue_return_home(citizen)
				_update_citizen_visual(citizen)
				continue

			citizen["home_visit_timer"] -= delta

			if citizen["home_visit_timer"] <= 0.0:
				if _begin_return_home(citizen):
					_update_citizen_visual(citizen)
					continue

				citizen["home_visit_timer"] = rng.randf_range(
					HOME_VISIT_INTERVAL_MIN,
					HOME_VISIT_INTERVAL_MAX
				)

			_choose_next_target(citizen)
			_update_citizen_visual(citizen)
			continue

		# Move toward the current target.
		citizen["move_progress"] += delta

		var duration = max(
			0.1,
			float(citizen["move_duration"])
		)

		if citizen["move_progress"] >= duration:
			var previous_grid = current

			citizen["grid_pos"] = target
			citizen["previous_grid"] = previous_grid
			citizen["move_progress"] = 0.0

			if citizen["returning_home"]:
				_continue_return_home(citizen)
			else:
				_choose_next_target(citizen)

		_update_citizen_visual(citizen)


func _initialize_citizen_state(citizen):
	if not citizen.has("grid_pos"):
		citizen["grid_pos"] = citizen.get(
			"home_grid",
			Vector2.ZERO
		)

	if not citizen.has("target_grid"):
		citizen["target_grid"] = citizen["grid_pos"]

	if not citizen.has("previous_grid"):
		citizen["previous_grid"] = citizen["grid_pos"]

	if not citizen.has("move_progress"):
		citizen["move_progress"] = 0.0

	if not citizen.has("move_duration"):
		citizen["move_duration"] = 1.0

	if not citizen.has("at_home"):
		citizen["at_home"] = false

	if not citizen.has("returning_home"):
		citizen["returning_home"] = false

	if not citizen.has("home_timer"):
		citizen["home_timer"] = 0.0

	if not citizen.has("home_visit_timer"):
		citizen["home_visit_timer"] = rng.randf_range(
			HOME_VISIT_INTERVAL_MIN,
			HOME_VISIT_INTERVAL_MAX
		)


# --------------------------------------------------
# RESIDENTS
# --------------------------------------------------

func sync_residents():
	if world == null:
		return

	var homes = {}

	for building in world.placed_buildings:
		var building_id = str(building.get("id", ""))

		if not _is_residential(building_id):
			continue

		var grid = building.get("grid", Vector2.ZERO)
		var key = _home_key(building_id, grid)

		homes[key] = {
			"id": building_id,
			"grid": grid,
			"capacity": _home_capacity(building_id)
		}

	var existing = {}

	for citizen in citizens:
		var key = str(citizen.get("home_key", ""))

		if not existing.has(key):
			existing[key] = []

		existing[key].append(citizen)

	var updated = []

	for key in homes.keys():
		var home = homes[key]
		var residents = existing.get(key, [])
		var capacity = int(home["capacity"])

		for citizen in residents:
			if _count_home_residents(updated, key) >= capacity:
				break

			updated.append(citizen)

		while _count_home_residents(updated, key) < capacity:
			updated.append(
				_create_citizen(key, home["grid"])
			)

	citizens = updated

	_rebuild_visuals()
	_sync_jobs()

	if world.has_method("_update_population_label"):
		world._update_population_label()

	print("POPULATION UPDATED: ", citizens.size())


func _count_home_residents(list, home_key):
	var count = 0

	for citizen in list:
		if str(citizen.get("home_key", "")) == home_key:
			count += 1

	return count


func _create_citizen(home_key, home_grid):
	var citizen_id = "citizen_" + str(next_citizen_id)
	next_citizen_id += 1

	var start_grid = _find_nearest_connected_road(home_grid)

	var citizen = {
		"id": citizen_id,
		"home_key": home_key,
		"home_grid": home_grid,
		"grid_pos": start_grid,
		"target_grid": start_grid,
		"previous_grid": start_grid,
		"move_progress": 0.0,
		"move_duration": 1.0,
		"skin_seed": rng.randi_range(1, 1000000),
		"wallet": 100,
		"job_id": "",
		"work_grid": home_grid,
		"at_home": false,
		"returning_home": false,
		"home_timer": 0.0,
		"home_visit_timer": rng.randf_range(
			HOME_VISIT_INTERVAL_MIN,
			HOME_VISIT_INTERVAL_MAX
		)
	}

	_choose_next_target(citizen)

	return citizen


func _is_residential(building_id):
	return building_id in [
		"small_house",
		"normal_house",
		"low_apartment",
		"high_apartment",
		"residential_tower"
	]


func _home_capacity(building_id):
	match building_id:
		"small_house":
			return 2
		"normal_house":
			return 4
		"low_apartment":
			return 8
		"high_apartment":
			return 14
		"residential_tower":
			return 22

	return 0


func _home_key(building_id, grid):
	return "%s:%d:%d" % [
		building_id,
		int(grid.x),
		int(grid.y)
	]


# --------------------------------------------------
# ROAD HELPERS
# --------------------------------------------------

func _get_road_system():
	if world == null:
		return null

	return world.get_node_or_null("../RoadSystem")


func _get_road_tiles():
	var result = []
	var road_system = _get_road_system()

	if road_system == null:
		return result

	for road in road_system.roads:
		var grid = road.get("grid", Vector2.ZERO)

		if not result.has(grid):
			result.append(grid)

	return result


func _has_road_at(grid):
	var road_system = _get_road_system()

	if road_system == null:
		return false

	return road_system.has_road(grid)


func _has_road_connection(from_grid, to_grid):
	var difference = to_grid - from_grid

	if abs(difference.x) + abs(difference.y) != 1:
		return false

	return (
		_has_road_at(from_grid)
		and _has_road_at(to_grid)
	)


func _find_nearest_connected_road(from_grid):
	var road_tiles = _get_road_tiles()

	if road_tiles.empty():
		return from_grid

	var nearest = road_tiles[0]
	var nearest_distance = 999999

	for road_grid in road_tiles:
		var distance = (
			abs(from_grid.x - road_grid.x)
			+ abs(from_grid.y - road_grid.y)
		)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest = road_grid

	return nearest


func _get_building_footprint(building_id):
	if world != null and world.building_footprints != null:
		return world.building_footprints.get_footprint(building_id)

	return Vector2(1, 1)


# --------------------------------------------------
# HOME ROAD AND PATHFINDING
# --------------------------------------------------

func _get_home_building_id(citizen):
	var home_key = str(citizen.get("home_key", ""))

	for building in world.placed_buildings:
		var building_id = str(building.get("id", ""))
		var grid = building.get("grid", Vector2.ZERO)

		if _home_key(building_id, grid) == home_key:
			return building_id

	return "small_house"


func _get_home_adjacent_roads(citizen):
	var result = []

	var home_grid = citizen.get("home_grid", Vector2.ZERO)
	var building_id = _get_home_building_id(citizen)
	var footprint = _get_building_footprint(building_id)
	var road_tiles = _get_road_tiles()

	for x in range(int(footprint.x)):
		for y in range(int(footprint.y)):
			var tile = home_grid + Vector2(x, y)

			var adjacent_tiles = [
				tile + Vector2(1, 0),
				tile + Vector2(-1, 0),
				tile + Vector2(0, 1),
				tile + Vector2(0, -1)
			]

			for road_grid in adjacent_tiles:
				if road_tiles.has(road_grid) and not result.has(road_grid):
					result.append(road_grid)

	return result


func _find_path_to_home(citizen):
	var start = citizen.get("grid_pos", Vector2.ZERO)
	var goals = _get_home_adjacent_roads(citizen)
	var road_tiles = _get_road_tiles()

	if goals.empty():
		return []

	if goals.has(start):
		return [start]

	if not road_tiles.has(start):
		return []

	var queue = [start]
	var came_from = {}
	var visited = [start]
	var found_goal = Vector2.ZERO
	var found = false

	while not queue.empty():
		var current = queue.pop_front()

		if goals.has(current):
			found_goal = current
			found = true
			break

		var neighbors = [
			current + Vector2(1, 0),
			current + Vector2(0, 1),
			current + Vector2(-1, 0),
			current + Vector2(0, -1)
		]

		for neighbor in neighbors:
			if not road_tiles.has(neighbor):
				continue

			if visited.has(neighbor):
				continue

			if not _has_road_connection(current, neighbor):
				continue

			visited.append(neighbor)
			came_from[neighbor] = current
			queue.append(neighbor)

	if not found:
		return []

	var path = []
	var step = found_goal

	path.append(step)

	while step != start:
		if not came_from.has(step):
			return []

		step = came_from[step]
		path.push_front(step)

	return path


func _begin_return_home(citizen):
	var path = _find_path_to_home(citizen)

	if path.empty():
		return false

	citizen["returning_home"] = true
	citizen["move_progress"] = 0.0

	if path.size() <= 1:
		_enter_home(citizen)
		return true

	citizen["target_grid"] = path[1]
	citizen["move_duration"] = 1.0

	return true


func _continue_return_home(citizen):
	var path = _find_path_to_home(citizen)

	if path.empty():
		citizen["returning_home"] = false
		citizen["home_visit_timer"] = rng.randf_range(
			HOME_VISIT_INTERVAL_MIN,
			HOME_VISIT_INTERVAL_MAX
		)
		_choose_next_target(citizen)
		return

	if path.size() <= 1:
		_enter_home(citizen)
		return

	citizen["target_grid"] = path[1]
	citizen["move_progress"] = 0.0
	citizen["move_duration"] = 1.0


func _enter_home(citizen):
	citizen["at_home"] = true
	citizen["returning_home"] = false
	citizen["home_timer"] = rng.randf_range(
		HOME_STAY_MIN,
		HOME_STAY_MAX
	)

	citizen["move_progress"] = 0.0
	citizen["target_grid"] = citizen["grid_pos"]

	var citizen_id = str(citizen["id"])

	if visuals.has(citizen_id):
		visuals[citizen_id].visible = false


# --------------------------------------------------
# ROAD MOVEMENT
# --------------------------------------------------

func _choose_next_target(citizen):
	var current = citizen.get("grid_pos", Vector2.ZERO)
	var previous = citizen.get("previous_grid", current)
	var road_tiles = _get_road_tiles()

	if road_tiles.empty():
		citizen["target_grid"] = current
		citizen["move_progress"] = 0.0
		return

	if not road_tiles.has(current):
		var nearest = _find_nearest_connected_road(current)

		citizen["grid_pos"] = nearest
		citizen["target_grid"] = nearest
		citizen["previous_grid"] = nearest
		citizen["move_progress"] = 0.0

		current = nearest
		previous = nearest

	var neighbors = [
		current + Vector2(1, 0),
		current + Vector2(0, 1),
		current + Vector2(-1, 0),
		current + Vector2(0, -1)
	]

	var candidates = []

	for neighbor in neighbors:
		if not road_tiles.has(neighbor):
			continue

		if not _has_road_connection(current, neighbor):
			continue

		if not candidates.has(neighbor):
			candidates.append(neighbor)

	if candidates.size() > 1 and candidates.has(previous):
		candidates.erase(previous)

	if candidates.empty():
		if (
			previous != current
			and road_tiles.has(previous)
			and _has_road_connection(current, previous)
		):
			candidates.append(previous)
		else:
			citizen["target_grid"] = current
			citizen["move_progress"] = 0.0
			return

	var next_grid = candidates[
		rng.randi_range(0, candidates.size() - 1)
	]

	citizen["target_grid"] = next_grid
	citizen["move_progress"] = 0.0
	citizen["move_duration"] = 1.0


# --------------------------------------------------
# VISUALS
# --------------------------------------------------

func _update_citizen_visual(citizen):
	var citizen_id = str(citizen["id"])

	if not visuals.has(citizen_id):
		return

	var visual = visuals[citizen_id]

	if citizen.get("at_home", false):
		visual.visible = false
		return

	visual.visible = true

	var start = citizen["grid_pos"]
	var target = citizen["target_grid"]

	var duration = max(
		0.1,
		float(citizen["move_duration"])
	)

	var weight = clamp(
		float(citizen["move_progress"]) / duration,
		0.0,
		1.0
	)

	var grid_pos = start.linear_interpolate(target, weight)

	visual.position = world.grid_to_screen(
		grid_pos,
		Vector2(600, 130)
	)

	visual.z_index = int(
		(grid_pos.x + grid_pos.y) * 10
	) + 5


func _rebuild_visuals():
	for child in get_children():
		remove_child(child)
		child.free()

	visuals.clear()

	var visual_script = load(CITIZEN_VISUAL_PATH)

	if visual_script == null:
		push_error("Could not load CitizenVisual.gd")
		return

	for citizen in citizens:
		_initialize_citizen_state(citizen)

		var citizen_id = str(citizen["id"])
		var visual = visual_script.new()

		visual.name = citizen_id
		add_child(visual)

		visual.setup(
			int(citizen.get("skin_seed", 0))
		)

		visual.scale = Vector2(0.7, 0.7)

		visuals[citizen_id] = visual
		_update_citizen_visual(citizen)


# --------------------------------------------------
# SAVE / LOAD
# --------------------------------------------------

func get_save_data():
	var result = []

	for citizen in citizens:
		result.append({
			"id": str(citizen.get("id", "")),
			"home_key": str(citizen.get("home_key", "")),
			"home_grid": _vector_to_data(
				citizen.get("home_grid", Vector2.ZERO)
			),
			"grid_pos": _vector_to_data(
				citizen.get("grid_pos", Vector2.ZERO)
			),
			"target_grid": _vector_to_data(
				citizen.get("target_grid", Vector2.ZERO)
			),
			"previous_grid": _vector_to_data(
				citizen.get("previous_grid", Vector2.ZERO)
			),
			"move_progress": float(
				citizen.get("move_progress", 0.0)
			),
			"move_duration": float(
				citizen.get("move_duration", 1.0)
			),
			"skin_seed": int(
				citizen.get("skin_seed", 0)
			),
			"job_id": str(
				citizen.get("job_id", "")
			),
			"work_grid": _vector_to_data(
				citizen.get(
					"work_grid",
					citizen.get("home_grid", Vector2.ZERO)
				)
			),
			"wallet": int(
				citizen.get("wallet", 0)
			),
			"at_home": bool(
				citizen.get("at_home", false)
			),
			"returning_home": bool(
				citizen.get("returning_home", false)
			),
			"home_timer": float(
				citizen.get("home_timer", 0.0)
			),
			"home_visit_timer": float(
				citizen.get("home_visit_timer", 0.0)
			)
		})

	return result


func load_data(saved_citizens):
	citizens.clear()
	next_citizen_id = 1

	for saved in saved_citizens:
		if typeof(saved) != TYPE_DICTIONARY:
			continue

		var citizen_id = str(saved.get("id", ""))

		if citizen_id == "":
			continue

		var citizen_number = int(
			citizen_id.replace("citizen_", "")
		)

		next_citizen_id = max(
			next_citizen_id,
			citizen_number + 1
		)

		var home_grid = _data_to_vector(
			saved.get("home_grid", {})
		)

		var grid_pos = _data_to_vector(
			saved.get("grid_pos", {})
		)

		citizens.append({
			"id": citizen_id,
			"home_key": str(
				saved.get("home_key", "")
			),
			"home_grid": home_grid,
			"grid_pos": grid_pos,
			"target_grid": _data_to_vector(
				saved.get(
					"target_grid",
					saved.get("grid_pos", {})
				)
			),
			"previous_grid": _data_to_vector(
				saved.get(
					"previous_grid",
					saved.get("grid_pos", {})
				)
			),
			"move_progress": float(
				saved.get("move_progress", 0.0)
			),
			"move_duration": max(
				0.1,
				float(saved.get("move_duration", 1.0))
			),
			"skin_seed": int(
				saved.get("skin_seed", 0)
			),
			"job_id": str(
				saved.get("job_id", "")
			),
			"work_grid": _data_to_vector(
				saved.get(
					"work_grid",
					saved.get("home_grid", {})
				)
			),
			"wallet": max(
				100,
				int(saved.get("wallet", 0))
			),
			"at_home": bool(
				saved.get("at_home", false)
			),
			"returning_home": bool(
				saved.get("returning_home", false)
			),
			"home_timer": float(
				saved.get("home_timer", 0.0)
			),
			"home_visit_timer": float(
				saved.get(
					"home_visit_timer",
					rng.randf_range(
						HOME_VISIT_INTERVAL_MIN,
						HOME_VISIT_INTERVAL_MAX
					)
				)
			)
		})

	sync_residents()


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


# --------------------------------------------------
# JOBS AND EMPLOYMENT
# --------------------------------------------------

func _sync_jobs():
	if world == null:
		return

	var available_jobs = []

	for building in world.placed_buildings:
		var building_id = str(
			building.get("id", "")
		)

		var capacity = int(
			JOB_CAPACITY.get(building_id, 0)
		)

		var building_grid = building.get(
			"grid",
			Vector2.ZERO
		)

		for slot in range(capacity):
			available_jobs.append({
				"building_id": building_id,
				"grid": building_grid,
				"slot": slot,
				"occupied": false
			})

	for citizen in citizens:
		if not citizen.has("job_id"):
			citizen["job_id"] = ""

		if not citizen.has("work_grid"):
			citizen["work_grid"] = citizen.get(
				"home_grid",
				Vector2.ZERO
			)

		var old_job_id = str(
			citizen.get("job_id", "")
		)

		var old_work_grid = citizen.get(
			"work_grid",
			citizen.get("home_grid", Vector2.ZERO)
		)

		var job_preserved = false

		if old_job_id != "":
			for job in available_jobs:
				if job["occupied"]:
					continue

				if str(job["building_id"]) != old_job_id:
					continue

				if job["grid"] != old_work_grid:
					continue

				job["occupied"] = true
				job_preserved = true
				break

		if not job_preserved:
			citizen["job_id"] = ""
			citizen["work_grid"] = citizen.get(
				"home_grid",
				Vector2.ZERO
			)

	for citizen in citizens:
		if str(citizen.get("job_id", "")) != "":
			continue

		for job in available_jobs:
			if job["occupied"]:
				continue

			job["occupied"] = true
			citizen["job_id"] = job["building_id"]
			citizen["work_grid"] = job["grid"]
			break

	var employed = 0

	for citizen in citizens:
		if str(citizen.get("job_id", "")) != "":
			employed += 1

	print(
		"EMPLOYMENT UPDATED | Population: ",
		citizens.size(),
		" | Employed: ",
		employed,
		" | Unemployed: ",
		citizens.size() - employed
	)


func get_employment_stats():
	var employed = 0

	for citizen in citizens:
		if str(citizen.get("job_id", "")) != "":
			employed += 1

	return {
		"population": citizens.size(),
		"employed": employed,
		"unemployed": citizens.size() - employed
	}


# --------------------------------------------------
# CITIZEN SHOPPING
# --------------------------------------------------

func _process_citizen_shopping():
	if world == null:
		return

	if not ("mineral_market_system" in world):
		return

	var market = world.mineral_market_system

	if market == null:
		return

	var markets = []

	for building in world.placed_buildings:
		if str(building.get("id", "")) == "mineral_market":
			markets.append(building)

	if markets.empty():
		return

	for citizen in citizens:
		var wallet = int(
			citizen.get("wallet", 0)
		)

		if wallet <= 0:
			continue

		var products = [
			"stone",
			"iron_ore"
		]

		var product_id = products[
			rng.randi_range(0, products.size() - 1)
		]

		var price = market.get_sell_price(product_id)

		if wallet < price:
			continue

		if market.get_stock(product_id) <= 0:
			continue

		var market_building = markets[
			rng.randi_range(0, markets.size() - 1)
		]

		var result = market.sell_to_customer(
			product_id,
			1,
			wallet,
			market_building
		)

		if not result.get("success", false):
			continue

		citizen["wallet"] = int(
			result["remaining_money"]
		)

		print(
			"CITIZEN PURCHASE | Citizen: ",
			citizen.get("id", ""),
			" | Product: ",
			product_id,
			" | Paid: $",
			result["cost"],
			" | Wallet: $",
			citizen["wallet"]
		)
