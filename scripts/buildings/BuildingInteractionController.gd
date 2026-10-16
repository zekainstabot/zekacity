
extends Reference

# ZekaCity - BuildingInteractionController.gd
# Godot 3.6

func handle_input(event, world):
	if not event is InputEventMouseButton:
		return

	if event.button_index != BUTTON_LEFT:
		return

	if not event.pressed:
		return

	var mouse_pos = world.get_local_mouse_position()

	if world.moving_building_index >= 0:
		_handle_building_move(mouse_pos, world)
		return

	if world.road_placement_direction >= 0:
		_handle_road_placement(mouse_pos, world)
		return

	if world.selected_building_for_placement != "":
		_handle_building_placement(mouse_pos, world)
		return

	var hit_building = world._find_building_at_position(mouse_pos)

	if hit_building >= 0:
		if world.buy_land_button != null:
			world.buy_land_button.visible = false

		_select_building(hit_building, world)
		return

	_select_land(mouse_pos, world)


func _handle_building_move(mouse_pos, world):
	var center = Vector2(600, 130)

	var destination = world.land_selection.get_selected_tile(
		mouse_pos,
		center,
		world.grid_size,
		world.tile_width,
		world.tile_height
	)

	if destination.x < 0:
		return

	var result = world.building_actions.move_building(
		world.moving_building_index,
		destination,
		world.grid_size,
		world.placed_buildings,
		world.building_footprints,
		world.land_system,
		world.get_node_or_null("../RoadSystem")
	)

	if result["success"]:
		print("BUILDING MOVED TO: ", destination)

		world.selected_building_index = world.moving_building_index
		world.selected_x = int(destination.x)
		world.selected_y = int(destination.y)

		world.building_visibility.set_selected_building(
			world.selected_building_index
		)

		if world.building_system != null:
			world.building_system.set_buildings(
				world.placed_buildings
			)
	else:
		print("BUILDING MOVE FAILED: ", result["error"])

	world.moving_building_index = -1
	world.moving_building_origin = Vector2(-1, -1)

	world._refresh_building_visuals()
	world.update()

	if (
		world.building_action_panel != null
		and world.selected_building_index >= 0
		and world.selected_building_index < world.placed_buildings.size()
	):
		world.building_action_panel.show_for_building(
			str(
				world.placed_buildings[
					world.selected_building_index
				]["id"]
			)
		)


func _select_building(building_index, world):
	world.selected_building_index = building_index

	var building = world.placed_buildings[building_index]

	world.selected_x = int(building["grid"].x)
	world.selected_y = int(building["grid"].y)

	world.building_visibility.set_selected_building(
		building_index
	)

	print(
		"SELECTED BUILDING: ",
		building["id"],
		" | INDEX: ",
		building_index
	)

	world._refresh_building_visuals()
	world.update()

	if world.building_action_panel != null:
		world.building_action_panel.show_for_building(
			str(building["id"])
		)


func _select_land(mouse_pos, world):
	var center = Vector2(600, 130)

	var selected_tile = world.land_selection.get_selected_tile(
		mouse_pos,
		center,
		world.grid_size,
		world.tile_width,
		world.tile_height
	)

	if selected_tile.x < 0:
		return

	world.selected_x = int(selected_tile.x)
	world.selected_y = int(selected_tile.y)

	world.selected_building_index = -1

	var clicked_grid = Vector2(
		world.selected_x,
		world.selected_y
	)

	for i in range(world.placed_buildings.size() - 1, -1, -1):
		var building = world.placed_buildings[i]
		var footprint = world.building_footprints.get_footprint(
			building["id"]
		)
		var origin = building["grid"]

		if (
			clicked_grid.x >= origin.x
			and clicked_grid.y >= origin.y
			and clicked_grid.x < origin.x + footprint.x
			and clicked_grid.y < origin.y + footprint.y
		):
			world.selected_building_index = i
			world.building_visibility.set_selected_building(i)
			break

	if world.selected_building_index == -1:
		world.building_visibility.clear_selection()

		if world.building_action_panel != null:
			world.building_action_panel.hide_panel()

		if world.buy_land_button != null:
			world.buy_land_button.visible = not world.land_system.is_owned(
				clicked_grid
			)
	else:
		if world.building_action_panel != null:
			world.building_action_panel.show_for_building(
				str(
					world.placed_buildings[
						world.selected_building_index
					]["id"]
				)
			)

		if world.buy_land_button != null:
			world.buy_land_button.visible = false

	world._refresh_building_visuals()
	world.update()


func _handle_road_placement(mouse_pos, world):
	var center = Vector2(600, 130)

	var selected_tile = world.land_selection.get_selected_tile(
		mouse_pos,
		center,
		world.grid_size,
		world.tile_width,
		world.tile_height
	)

	if selected_tile.x < 0:
		return

	world.selected_x = int(selected_tile.x)
	world.selected_y = int(selected_tile.y)

	world._confirm_place_road()


func _handle_building_placement(mouse_pos, world):
	var center = Vector2(600, 130)

	var selected_tile = world.land_selection.get_selected_tile(
		mouse_pos,
		center,
		world.grid_size,
		world.tile_width,
		world.tile_height
	)

	if selected_tile.x < 0:
		return

	world.selected_x = int(selected_tile.x)
	world.selected_y = int(selected_tile.y)

	world._place_building(
		world.selected_building_for_placement
	)
