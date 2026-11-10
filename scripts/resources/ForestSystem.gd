extends Node2D

# ZekaCity - ForestSystem.gd (Godot 3.6)
# Procedural forest patches. Trees occupy map tiles and can be harvested by
# nearby woodcutters; saved tree positions are restored between sessions.

var world = null
var trees = []
var rng = RandomNumberGenerator.new()
var map_center = Vector2(600, 130)

func initialize(world_node):
	world = world_node
	rng.randomize()
	if trees.empty():
		_generate_forest()
	update()
	print("ForestSystem initialized | Trees: ", trees.size())


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
	trees.remove(best_index)
	update()
	return true


func restore_tree_near(grid_pos, radius = 6):
	var best_grid = Vector2(-1, -1)
	var best_distance = 999999.0
	for x in range(max(0, int(grid_pos.x) - radius), min(world.grid_size, int(grid_pos.x) + radius + 1)):
		for y in range(max(0, int(grid_pos.y) - radius), min(world.grid_size, int(grid_pos.y) + radius + 1)):
			var tile = Vector2(x, y)
			var distance = abs(tile.x - grid_pos.x) + abs(tile.y - grid_pos.y)
			if distance <= radius and distance < best_distance and not _has_tree_at(tile):
				best_distance = distance
				best_grid = tile
	if best_grid.x >= 0:
		trees.append({"id": trees.size() + 1, "grid": best_grid, "health": 1})
		update()
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
	return result


func load_data(data):
	if typeof(data) != TYPE_ARRAY:
		return
	trees.clear()
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
		trees.append({
			"id": int(item.get("id", trees.size() + 1)),
			"grid": tile,
			"health": max(1, int(item.get("health", 1)))
		})
	update()


func _draw():
	if world == null:
		return
	for tree in trees:
		var pos = world.grid_to_screen(tree["grid"], map_center)
		var sway = float(int(tree.get("id", 0)) % 3) * 2.0
		# Trunk
		draw_rect(Rect2(pos + Vector2(-3, -15), Vector2(6, 18)), Color(0.34, 0.20, 0.10))
		# Layered pine canopy
		draw_colored_polygon(PoolVector2Array([
			pos + Vector2(-18 + sway, -12), pos + Vector2(0, -48),
			pos + Vector2(18 + sway, -12)
		]), Color(0.10, 0.36, 0.19))
		draw_colored_polygon(PoolVector2Array([
			pos + Vector2(-14, -25), pos + Vector2(0, -58),
			pos + Vector2(14, -25)
		]), Color(0.16, 0.48, 0.24))
		draw_circle(pos + Vector2(-5, -38), 3.0, Color(0.34, 0.62, 0.31))
