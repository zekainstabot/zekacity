extends Reference

# =========================================
# ZekaCity - BuildingVisibility.gd
# Godot 3.6
# مدیریت دید ساختمان‌های پشت سر
# =========================================

var selected_building_index = -1

var normal_alpha = 1.0
var transparent_alpha = 0.25


func set_selected_building(index):
	selected_building_index = index


func clear_selection():
	selected_building_index = -1


func get_selected_building_index():
	return selected_building_index


func get_building_alpha(index, placed_buildings):
	if selected_building_index < 0:
		return normal_alpha

	if selected_building_index >= placed_buildings.size():
		return normal_alpha

	if index < 0 or index >= placed_buildings.size():
		return normal_alpha

	if index == selected_building_index:
		return normal_alpha

	var selected_building = placed_buildings[selected_building_index]
	var current_building = placed_buildings[index]

	var selected_grid = selected_building["grid"]
	var current_grid = current_building["grid"]

	var selected_depth = selected_grid.x + selected_grid.y
	var current_depth = current_grid.x + current_grid.y

	if current_depth > selected_depth:
		return transparent_alpha

	return normal_alpha


func get_front_building_indices(placed_buildings):
	var result = []

	if selected_building_index < 0:
		return result

	if selected_building_index >= placed_buildings.size():
		return result

	var selected_building = placed_buildings[selected_building_index]
	var selected_grid = selected_building["grid"]
	var selected_depth = selected_grid.x + selected_grid.y

	for i in range(placed_buildings.size()):
		if i == selected_building_index:
			continue

		var current_grid = placed_buildings[i]["grid"]
		var current_depth = current_grid.x + current_grid.y

		if current_depth > selected_depth:
			result.append(i)

	return result
