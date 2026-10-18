
extends Node2D

# ZekaCity - CitizenSystem.gd
# Godot 3.6
# Automatic residents, movement and persistence

const CITIZEN_VISUAL_PATH = "res://scripts/citizens/CitizenVisual.gd"

var world = null
var citizens = []
var visuals = {}
var next_citizen_id = 1
var rng = RandomNumberGenerator.new()


func initialize(world_node):
	world = world_node
	rng.randomize()
	set_process(true)


func _process(delta):
	if world == null:
		return

	for i in range(citizens.size()):
		var citizen = citizens[i]

		if not citizen.has("grid_pos"):
			citizen["grid_pos"] = citizen.get(
				"home_grid",
				Vector2.ZERO
			)

		if not citizen.has("target_grid"):
			citizen["target_grid"] = citizen["grid_pos"]

		if not citizen.has("move_progress"):
			citizen["move_progress"] = 0.0

		if not citizen.has("move_duration"):
			citizen["move_duration"] = 1.0

		citizen["move_progress"] += delta

		var duration = max(
			0.1,
			float(citizen["move_duration"])
		)

		if citizen["move_progress"] >= duration:
			citizen["grid_pos"] = citizen["target_grid"]
			citizen["move_progress"] = 0.0
			_choose_next_target(citizen)

		_update_citizen_visual(citizen)


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
			if updated.size() >= 0 and updated.size() < 100000:
				if _count_home_residents(updated, key) >= capacity:
					break

				updated.append(citizen)

		while _count_home_residents(updated, key) < capacity:
			updated.append(_create_citizen(
				key,
				home["grid"]
			))

	citizens = updated
	_rebuild_visuals()


func _count_home_residents(list, home_key):
	var count = 0

	for citizen in list:
		if str(citizen.get("home_key", "")) == home_key:
			count += 1

	return count


func _create_citizen(home_key, home_grid):
	var citizen_id = "citizen_" + str(next_citizen_id)
	next_citizen_id += 1

	var citizen = {
		"id": citizen_id,
		"home_key": home_key,
		"home_grid": home_grid,
		"grid_pos": home_grid,
		"target_grid": home_grid,
		"move_progress": 0.0,
		"move_duration": 1.0,
		"skin_seed": rng.randi_range(1, 1000000)
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


func _choose_next_target(citizen):
	var candidates = []
	var road_system = world.get_node_or_null("../RoadSystem")

	if road_system != null and not road_system.roads.empty():
		for road in road_system.roads:
			var road_grid = road.get("grid", Vector2.ZERO)

			if road_grid != citizen["grid_pos"]:
				if not candidates.has(road_grid):
					candidates.append(road_grid)

	else:
		for tile in world.land_system.owned_tiles:
			if tile != citizen["grid_pos"]:
				if not candidates.has(tile):
					candidates.append(tile)

		if not candidates.has(citizen["home_grid"]):
			candidates.append(citizen["home_grid"])

	if candidates.empty():
		citizen["target_grid"] = citizen["home_grid"]
		citizen["move_duration"] = 1.0
		citizen["move_progress"] = 0.0
		return

	var target = candidates[
		rng.randi_range(0, candidates.size() - 1)
	]

	citizen["target_grid"] = target

	var distance = abs(
		target.x - citizen["grid_pos"].x
	) + abs(
		target.y - citizen["grid_pos"].y
	)

	citizen["move_duration"] = max(0.8, distance * 0.8)
	citizen["move_progress"] = 0.0


func _update_citizen_visual(citizen):
	var citizen_id = str(citizen["id"])

	if not visuals.has(citizen_id):
		return

	var visual = visuals[citizen_id]
	var start = citizen["grid_pos"]
	var target = citizen["target_grid"]
	var duration = max(0.1, float(citizen["move_duration"]))
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

	for citizen in citizens:
		var citizen_id = str(citizen["id"])
		var visual = visual_script.new()

		visual.name = citizen_id
		add_child(visual)
		visual.setup(int(citizen.get("skin_seed", 0)))

		visuals[citizen_id] = visual
		_update_citizen_visual(citizen)


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
			"move_progress": float(
				citizen.get("move_progress", 0.0)
			),
			"move_duration": float(
				citizen.get("move_duration", 1.0)
			),
			"skin_seed": int(citizen.get("skin_seed", 0))
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

		citizens.append({
			"id": citizen_id,
			"home_key": str(saved.get("home_key", "")),
			"home_grid": _data_to_vector(
				saved.get("home_grid", {})
			),
			"grid_pos": _data_to_vector(
				saved.get("grid_pos", {})
			),
			"target_grid": _data_to_vector(
				saved.get("target_grid", {})
			),
			"move_progress": float(
				saved.get("move_progress", 0.0)
			),
			"move_duration": max(
				0.1,
				float(saved.get("move_duration", 1.0))
			),
			"skin_seed": int(saved.get("skin_seed", 0))
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
