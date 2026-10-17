
extends Reference

# ZekaCity - BuildingInteractionController.gd
# Godot 3.6

func handle_input(event, world):
	if not event is InputEventMouseButton:
		return
	if event.button_index != BUTTON_LEFT or not event.pressed:
		return

	var mouse_pos = world.get_local_mouse_position()

	if world.moving_building_index >= 0:
		_handle_building_move(mouse_pos, world)
		return

	if world.road_placement_direction >= 0:
		_handle_road_placement(mouse_pos, world)
		return

	if world.has_meta("mine_placement_resource"):
		_handle_mine_placement(mouse_pos, world)
		return

	if world.selected_building_for_placement != "":
		_handle_building_placement(mouse_pos, world)
		return

	var mountain_system = world.get_node_or_null("../MountainSystem")
	if mountain_system != null:
		var clicked_mine_id = mountain_system.get_built_mine_at_position(mouse_pos)
		if clicked_mine_id != "":
			if world.buy_land_button != null:
				world.buy_land_button.visible = false
			if world.building_action_panel != null:
				world.building_action_panel.hide_panel()

			var ui_node = world.get_node_or_null("../UI")
			if ui_node != null:
				var mine_panel = ui_node.get_node_or_null("MineInfoPanel")
				if mine_panel == null:
					var panel_script = load("res://scripts/resources/MineInfoPanel.gd")
					mine_panel = Panel.new()
					mine_panel.set_script(panel_script)
					mine_panel.name = "MineInfoPanel"
					ui_node.add_child(mine_panel)

				mine_panel.rect_position = Vector2(20, 20)
				mine_panel.show_for_mine(mountain_system, clicked_mine_id, world)
			return

	var ui_node = world.get_node_or_null("../UI")
	if ui_node != null:
		var mine_panel = ui_node.get_node_or_null("MineInfoPanel")
		if mine_panel != null:
			mine_panel.hide_panel()

	var hit_building = world._find_building_at_position(mouse_pos)
	if hit_building >= 0:
		if world.buy_land_button != null:
			world.buy_land_button.visible = false

		_select_building(hit_building, world)
		return

	_select_land(mouse_pos, world)


func _handle_mine_placement(mouse_pos, world):
	var center = Vector2(600, 130)
	var selected_tile = world.land_selection.get_selected_tile(
		mouse_pos, center, world.grid_size,
		world.tile_width, world.tile_height
	)
	if selected_tile.x < 0:
		return

	var selected_resource = str(world.get_meta("mine_placement_resource", ""))
	var mountain_system = world.get_node_or_null("../MountainSystem")
	if mountain_system == null:
		push_error("MountainSystem node NOT FOUND")
		return

	var target_mountain_id = ""
	for mountain_id in mountain_system.mountains.keys():
		var mountain = mountain_system.mountains[mountain_id]
		if str(mountain["resource_id"]) != selected_resource:
			continue
		if mountain["mine_point"] == selected_tile:
			target_mountain_id = str(mountain_id)
			break

	if target_mountain_id == "":
		print("MINE PLACEMENT FAILED: Click the marked mining point on the correct mountain.")
		return
	if not mountain_system.can_build_mine(target_mountain_id):
		print("MINE PLACEMENT FAILED: A mine already exists here.")
		return
	if not mountain_system.build_mine(target_mountain_id):
		print("MINE PLACEMENT FAILED: Check the treasury balance and try again.")
		return

	world.remove_meta("mine_placement_resource")
	if world.has_method("_update_treasury_label"):
		world._update_treasury_label()
	print("MINE BUILT SUCCESSFULLY: ", target_mountain_id, " | Cost: $", mountain_system.mine_cost)


func _handle_building_move(mouse_pos, world):
	var center = Vector2(600, 130)
	var destination = world.land_selection.get_selected_tile(
		mouse_pos, center, world.grid_size,
		world.tile_width, world.tile_height
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
		world.building_visibility.set_selected_building(world.selected_building_index)
		if world.building_system != null:
			world.building_system.set_buildings(world.placed_buildings)
	else:
		print("BUILDING MOVE FAILED: ", result["error"])

	world.moving_building_index = -1
	world.moving_building_origin = Vector2(-1, -1)
	world._refresh_building_visuals()
	world.update()

	if world.building_action_panel != null:
		_show_selected_building_panel(world)


func _select_building(building_index, world):
	world.selected_building_index = building_index
	var building = world.placed_buildings[building_index]
	world.selected_x = int(building["grid"].x)
	world.selected_y = int(building["grid"].y)
	world.building_visibility.set_selected_building(building_index)

	print("SELECTED BUILDING: ", building["id"], " | INDEX: ", building_index)
	world._refresh_building_visuals()
	world.update()

	if world.building_action_panel != null:
		_show_selected_building_panel(world)


func _show_selected_building_panel(world):
	var index = world.selected_building_index

	if index < 0 or index >= world.placed_buildings.size():
		return

	var building_id = str(
		world.placed_buildings[index].get("id", "")
	)

	var display_name = str(
		world.building_names.get(building_id, building_id)
	)

	print("BUILDING PANEL DEBUG: ", building_id)
	print("WAREHOUSE COUNT: ", world.storage_system.get_warehouse_count())
	print("WAREHOUSE CAPACITY: ", world.storage_system.get_total_capacity())

	world.building_action_panel.show_for_building(
		display_name,
		world,
		building_id
	)


func _select_land(mouse_pos, world):
	var center = Vector2(600, 130)
	var selected_tile = world.land_selection.get_selected_tile(
		mouse_pos, center, world.grid_size,
		world.tile_width, world.tile_height
	)
	if selected_tile.x < 0:
		return

	world.selected_x = int(selected_tile.x)
	world.selected_y = int(selected_tile.y)
	world.selected_building_index = -1

	var clicked_grid = Vector2(world.selected_x, world.selected_y)

	for i in range(world.placed_buildings.size() - 1, -1, -1):
		var building = world.placed_buildings[i]
		var footprint = world.building_footprints.get_footprint(building["id"])
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
			world.buy_land_button.visible = not world.land_system.is_owned(clicked_grid)
	else:
		if world.building_action_panel != null:
			_show_selected_building_panel(world)
		if world.buy_land_button != null:
			world.buy_land_button.visible = false

	world._refresh_building_visuals()
	world.update()


func _handle_road_placement(mouse_pos, world):
	var center = Vector2(600, 130)
	var selected_tile = world.land_selection.get_selected_tile(
		mouse_pos, center, world.grid_size,
		world.tile_width, world.tile_height
	)
	if selected_tile.x < 0:
		return

	world.selected_x = int(selected_tile.x)
	world.selected_y = int(selected_tile.y)
	world._confirm_place_road()


func _handle_building_placement(mouse_pos, world):
	var center = Vector2(600, 130)
	var selected_tile = world.land_selection.get_selected_tile(
		mouse_pos, center, world.grid_size,
		world.tile_width, world.tile_height
	)
	if selected_tile.x < 0:
		return

	world.selected_x = int(selected_tile.x)
	world.selected_y = int(selected_tile.y)
	world._place_building(world.selected_building_for_placement)
