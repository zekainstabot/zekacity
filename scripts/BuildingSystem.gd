extends Node2D

# =========================================
# ZekaCity - BuildingSystem.gd
# Godot 3.6
# مدیریت مستقل اطلاعات ساختمان‌ها
# =========================================

var tile_width = 160
var tile_height = 80
var map_center = Vector2(600, 130)

var placed_buildings = []


# دریافت ساختمان‌ها از World
func set_buildings(buildings):
	placed_buildings = buildings.duplicate(true)
	update()


# تبدیل مختصات شبکه به مختصات صفحه
func grid_to_screen(grid_pos):
	return map_center + Vector2(
		(grid_pos.x - grid_pos.y) * tile_width / 2,
		(grid_pos.x + grid_pos.y) * tile_height / 2
	)


# بررسی اشغال بودن خانه
func is_tile_occupied(grid_pos):
	for building in placed_buildings:
		if building["grid"] == grid_pos:
			return true

	return false


# بررسی وجود پارک در خانه
func has_park_at(grid_pos):
	for building in placed_buildings:
		if building["grid"] == grid_pos:
			return building["id"] == "small_park"

	return false
