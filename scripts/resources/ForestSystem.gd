extends Node2D

# ZekaCity - ForestSystem.gd (Godot 3.6)
# Each tree is a separate depth-sorted CanvasItem so buildings can pass
# in front of or behind individual trees according to isometric ground depth.

var world = null
var trees = []
var rng = RandomNumberGenerator.new()
var map_center = Vector2(600, 130)
var tree_visuals_root = null
var regrowth_sites = []
const TREE_REGROWTH_SECONDS = 180.0


func initialize(world_node):
	world = world_node
	rng.randomize()
	set_process(true)
	_ensure_visual_root()
	if trees.empty():
		_generate_forest()
	_refresh_tree_visuals()
	print("ForestSystem initialized | Trees: ", trees.size())


func _ensure_visual_root():
	if tree_visuals_root != null and is_instance_valid(tree_visuals_root):
		return
	tree_visuals_root = Node2D.new()
	tree_visuals_root.name = "TreeVisuals"
	add_child(tree_visuals_root)


func _generate_forest():
	trees.clear()
	if world == null:
		return

	var mountain_system = world.get_node_or_null("../MountainSystem")
	var road_system = world.get_node_or_null("../RoadSystem")
	var centers = [
		Vector2(3, 17), Vector2(19, 4), Vector2(19, 19),
		Vector2(7, 22), Vector2(14, 11), Vector2(23, 12)
	]
	var tree_id = 1

	for center in centers:
		for attempt in range(28):
			var tile = center + Vector2(
				rng.randi_range(-2, 2),
				rng.randi_range(-2, 2)
			)
			if not world.land_system.is_inside_map(tile):
				continue
			if world.land_system.is_owned(tile):
				continue
			if road_system != null and road_system.has_road(tile):
				continue
			if mountain_system != null and mountain_system.is_grid_blocked(tile):
				continue
			if world.is_tile_occupied(tile):
				continue
			if _has_tree_at(tile):
				continue
			trees.append({
				"id": tree_id,
				"grid": tile,
				"health": 1
			})
			tree_id += 1


func _has_tree_at(tile):
	for tree in trees:
		if tree.get("grid", Vector2(-1, -1)) == tile:
			return true
	return false


func _is_valid_tree_tile(tile):
	if world == null or not world.land_system.is_inside_map(tile):
		return false
	if world.land_system.is_owned(tile):
		return false

	var road_system = world.get_node_or_null("../RoadSystem")
	var mountain_system = world.get_node_or_null("../MountainSystem")
	if road_system != null and road_system.has_road(tile):
		return false
	if mountain_system != null and mountain_system.is_grid_blocked(tile):
		return false
	if world.is_tile_occupied(tile) or _has_tree_at(tile):
		return false
	return true


func _get_next_tree_id():
	var next_id = 1
	for tree in trees:
		next_id = max(next_id, int(tree.get("id", 0)) + 1)
	return next_id


func _process(delta):
	if world == null or delta <= 0.0:
		return

	var changed = false
	for i in range(regrowth_sites.size() - 1, -1, -1):
		var site = regrowth_sites[i]
		site["remaining"] = float(site.get("remaining", TREE_REGROWTH_SECONDS)) - delta

		if site["remaining"] <= 0.0:
			var tile = site.get("grid", Vector2(-1, -1))
			if _is_valid_tree_tile(tile):
				trees.append({
					"id": _get_next_tree_id(),
					"grid": tile,
					"health": 1
				})
				regrowth_sites.remove(i)
				changed = true
			else:
				# Keep the regrowth site pending until construction or
				# road placement no longer blocks its original forest tile.
				site["remaining"] = 30.0

		regrowth_sites[i] = site if i < regrowth_sites.size() else site

	if changed:
		_refresh_tree_visuals()


func is_grid_blocked(grid_pos):
	return _has_tree_at(grid_pos)


func harvest_near(grid_pos, radius = 6):
	var best_index = -1
	var best_distance = 999999.0
	for i in range(trees.size()):
		var tree = trees[i]
		var distance = abs(tree["grid"].x - grid_pos.x) + abs(tree["grid"].y - grid_pos.y)
		if distance <= radius and distance < best_distance:
			best_distance = distance
			best_index = i
	if best_index == -1:
		return false
	var harvested_grid = trees[best_index].get("grid", Vector2(-1, -1))
	trees.remove(best_index)
	regrowth_sites.append({
		"grid": harvested_grid,
		"remaining": TREE_REGROWTH_SECONDS
	})
	_refresh_tree_visuals()
	return true


func restore_tree_near(grid_pos, radius = 6):
	var best_grid = Vector2(-1, -1)
	var best_distance = 999999.0
	for x in range(max(0, int(grid_pos.x) - radius), min(world.grid_size, int(grid_pos.x) + radius + 1)):
		for y in range(max(0, int(grid_pos.y) - radius), min(world.grid_size, int(grid_pos.y) + radius + 1)):
			var tile = Vector2(x, y)
			var distance = abs(tile.x - grid_pos.x) + abs(tile.y - grid_pos.y)
			if distance <= radius and distance < best_distance and _is_valid_tree_tile(tile):
				best_distance = distance
				best_grid = tile
	if best_grid.x >= 0:
		trees.append({"id": _get_next_tree_id(), "grid": best_grid, "health": 1})
		_refresh_tree_visuals()
		return true
	return false


func get_save_data():
	var result = []
	for tree in trees:
		result.append({
			"id": int(tree.get("id", 0)),
			"grid": {
				"x": float(tree["grid"].x),
				"y": float(tree["grid"].y)
			},
			"health": int(tree.get("health", 1))
		})
	for site in regrowth_sites:
		result.append({
			"regrowth": true,
			"grid": {
				"x": float(site["grid"].x),
				"y": float(site["grid"].y)
			},
			"remaining": max(0.0, float(site.get("remaining", TREE_REGROWTH_SECONDS)))
		})
	return result


func load_data(data):
	if typeof(data) != TYPE_ARRAY:
		return
	trees.clear()
	regrowth_sites.clear()
	for item in data:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var grid = item.get("grid", {})
		if typeof(grid) != TYPE_DICTIONARY:
			continue
		if not grid.has("x") or not grid.has("y"):
			continue
		var tile = Vector2(float(grid["x"]), float(grid["y"]))
		if world == null or not world.land_system.is_inside_map(tile):
			continue
		if bool(item.get("regrowth", false)):
			regrowth_sites.append({
				"grid": tile,
				"remaining": max(0.0, float(item.get("remaining", TREE_REGROWTH_SECONDS)))
			})
			continue
		if _has_tree_at(tile):
			continue
		trees.append({
			"id": int(item.get("id", _get_next_tree_id())),
			"grid": tile,
			"health": max(1, int(item.get("health", 1)))
		})
	_refresh_tree_visuals()


func _refresh_tree_visuals():
	_ensure_visual_root()
	for child in tree_visuals_root.get_children():
		tree_visuals_root.remove_child(child)
		child.free()

	if world == null:
		return

	for tree in trees:
		var visual = Node2D.new()
		visual.name = "Tree_" + str(tree.get("id", 0))
		visual.position = world.grid_to_screen(tree["grid"], map_center)
		# Same projected ground-depth scale used by BuildingVisual.
		visual.z_as_relative = false
		visual.z_index = int(clamp(round(visual.position.y), -4096, 4096))
		visual.set_script(load("res://scripts/resources/ForestTreeVisual.gd"))
		visual.set("tree_id", int(tree.get("id", 0)))
		tree_visuals_root.add_child(visual)
