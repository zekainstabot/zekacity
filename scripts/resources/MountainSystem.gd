
extends Node2D

# ZekaCity - MountainSystem
# Godot 3.6

var world = null
var city_treasury = null
var resource_manager = null
var mine_system = null
var storage_system = null

var mountains = {}
var mountain_size = 3
var mine_cost = 1500
var map_center = Vector2(600, 130)

var mountain_texture = preload("res://BuildingImages/mountain.png")

var stone_mine_texture = preload(
	"res://BuildingImages/stone_mine.png"
)

var iron_mine_texture = preload(
	"res://BuildingImages/iron_mine.png"
)

var rng = RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	set_process(true)


func initialize(world_node, treasury, ui_node = null):
	world = world_node
	city_treasury = treasury

	rng.randomize()
	print("MOUNTAIN RNG SEED: ", rng.seed)

	storage_system = world.storage_system
	resource_manager = world.resource_manager

	if storage_system == null or resource_manager == null:
		push_error("MountainSystem: Shared resource systems are missing")
		return

	resource_manager.set_storage_system(storage_system)

	mine_system = load(
		"res://scripts/resources/MineSystem.gd"
	).new()

	_generate_mountains()
	update()

	print("MountainSystem initialized")
	print("Mountains generated: ", mountains.size())
	print("StorageSystem connected to ResourceManager")


func _process(delta):
	if mine_system == null or resource_manager == null:
		return

	if world != null and storage_system != null:
		storage_system.sync_warehouses(
			world.placed_buildings
		)

	mine_system.advance(delta, resource_manager)


func _generate_mountains():
	mountains.clear()

	if world == null:
		push_error("MountainSystem: World reference is missing")
		return

	var placed_stone = false
	var placed_iron = false

	var max_anchor = int(world.grid_size) - mountain_size

	if max_anchor < 0:
		push_error("MountainSystem: Map is too small for mountains")
		return

	for attempt in range(500):
		if placed_stone and placed_iron:
			break

		var origin = Vector2(
			rng.randi_range(0, max_anchor),
			rng.randi_range(0, max_anchor)
		)

		if not _can_place_mountain(origin):
			continue

		var mountain_id = ""
		var resource_id = ""

		if not placed_stone:
			mountain_id = "stone_mountain"
			resource_id = "stone"
			placed_stone = true
		elif not placed_iron:
			mountain_id = "iron_mountain"
			resource_id = "iron_ore"
			placed_iron = true

		mountains[mountain_id] = {
			"resource_id": resource_id,
			"origin": origin,
			"mine_point": origin + Vector2(1, 1),
			"mine_built": false
		}

		print(
			"MOUNTAIN POSITION - ",
			mountain_id,
			": ",
			origin
		)

	if mountains.size() != 2:
		push_error("MountainSystem: Could not place both mountains")

	update()


func _can_place_mountain(origin):
	if world == null:
		return false

	var road_system = world.get_node_or_null("../RoadSystem")

	for x in range(mountain_size):
		for y in range(mountain_size):
			var tile = origin + Vector2(x, y)

			if not world.land_system.is_inside_map(tile):
				return false

			if world.land_system.is_owned(tile):
				return false

			if road_system != null and road_system.has_road(tile):
				return false

			for building in world.placed_buildings:
				if building.has("grid") and building["grid"] == tile:
					return false

			for existing in mountains.values():
				var existing_origin = existing["origin"]

				for ex in range(mountain_size):
					for ey in range(mountain_size):
						if existing_origin + Vector2(ex, ey) == tile:
							return false

	return true



func _get_mountain_draw_data(mountain):
	# Center the mountain over the full 3x3 isometric footprint.
	var origin = mountain["origin"]
	var center_grid = origin + Vector2(
		float(mountain_size) / 2.0,
		float(mountain_size) / 2.0
	)

	var center = world.grid_to_screen(center_grid, map_center)

	var texture_size = mountain_texture.get_size()

	# The footprint of a 3x3 area is 192 x 144 pixels.
	# Keep the texture aspect ratio and let it rise above the ground.
	var footprint_width = (
		float(mountain_size) * float(world.tile_width)
	)
	var footprint_height = (
		float(mountain_size) * float(world.tile_height)
	)

	var target_size = Vector2(
		footprint_width,
		max(footprint_height, 150.0)
	)

	var scale_factor = min(
		target_size.x / texture_size.x,
		target_size.y / texture_size.y
	)

	var draw_size = texture_size * scale_factor

	# Align the bottom center of the image to the footprint center.
	var draw_pos = center - Vector2(
		draw_size.x / 2.0,
		draw_size.y
	)

	return {
		"draw_pos": draw_pos,
		"draw_size": draw_size,
		"ground_center": center
	}


func _get_pickaxe_position(mountain):
	var draw_data = _get_mountain_draw_data(mountain)
	var draw_pos = draw_data["draw_pos"]
	var draw_size = draw_data["draw_size"]

	# تغییر این اعداد، محل کلنگ روی کوه را تغییر می‌دهد.
	return draw_pos + Vector2(
		draw_size.x * 0.50,
		draw_size.y * 0.55
	)
	
func get_unbuilt_mountain_at_position(mouse_pos, resource_id):
	if world == null:
		return ""

	for mountain_id in mountains.keys():
		var mountain = mountains[mountain_id]

		if mountain["mine_built"]:
			continue

		if str(mountain["resource_id"]) != str(resource_id):
			continue

		var pickaxe_pos = _get_pickaxe_position(mountain)

		var hit_rect = Rect2(
			pickaxe_pos - Vector2(24, 24),
			Vector2(48, 48)
		)

		if hit_rect.has_point(mouse_pos):
			return str(mountain_id)

	return ""


func _draw():
	if world == null or mountain_texture == null:
		return

	for mountain_id in mountains.keys():
		var mountain = mountains[mountain_id]
		var draw_data = _get_mountain_draw_data(mountain)

		var draw_pos = draw_data["draw_pos"]
		var draw_size = draw_data["draw_size"]

		# Draw mountain image.
		draw_texture_rect(
			mountain_texture,
			Rect2(draw_pos, draw_size),
			false
		)

		var is_iron = str(mountain["resource_id"]) == "iron_ore"

		if mountain["mine_built"]:
			var mine_texture = stone_mine_texture

			if is_iron:
				mine_texture = iron_mine_texture

			_draw_mine_texture(
				mountain,
				mine_texture
			)
		else:
			# Show the pickaxe marker before construction.
			var pickaxe_pos = _get_pickaxe_position(mountain)

			draw_line(
				pickaxe_pos + Vector2(-5, 7),
				pickaxe_pos + Vector2(6, -7),
				Color(0.40, 0.23, 0.12),
				4.0
			)

			draw_line(
				pickaxe_pos + Vector2(-10, -6),
				pickaxe_pos + Vector2(9, -9),
				Color(0.75, 0.78, 0.82),
				5.0
			)

func _draw_mine_texture(mountain, mine_texture):
	if mine_texture == null:
		return

	var marker_pos = world.grid_to_screen(
		mountain["mine_point"],
		map_center
	)

	var texture_size = mine_texture.get_size()

	if texture_size.x <= 0 or texture_size.y <= 0:
		return

	# Fit the mine sprite while preserving its aspect ratio.
	var target_size = Vector2(80, 72)

	var scale_factor = min(
		target_size.x / texture_size.x,
		target_size.y / texture_size.y
	)

	var draw_size = texture_size * scale_factor

	# Align the bottom center of the mine sprite to its grid point.
	var draw_pos = marker_pos - Vector2(
		draw_size.x / 2.0,
		draw_size.y
	)

	draw_texture_rect(
		mine_texture,
		Rect2(draw_pos, draw_size),
		false
	)

func is_grid_blocked(grid_pos):
	for mountain in mountains.values():
		var origin = mountain["origin"]

		for x in range(mountain_size):
			for y in range(mountain_size):
				if origin + Vector2(x, y) == grid_pos:
					return true

	return false


func can_build_mine(mountain_id):
	if not mountains.has(mountain_id):
		return false

	return not mountains[mountain_id]["mine_built"]


func build_mine(mountain_id):
	if not can_build_mine(mountain_id):
		return false

	if city_treasury == null or mine_system == null:
		return false

	if not city_treasury.can_afford(mine_cost):
		return false

	var resource_id = str(mountains[mountain_id]["resource_id"])
	var reserve = 0

	if resource_id == "iron_ore":
		reserve = rng.randi_range(100, 300)

	if not mine_system.build_mine(
		mountain_id,
		resource_id,
		reserve
	):
		return false

	if not city_treasury.spend(mine_cost):
		mine_system.mines.erase(mountain_id)
		return false

	mountains[mountain_id]["mine_built"] = true
	update()

	return true


func get_mine_point(mountain_id):
	if not mountains.has(mountain_id):
		return Vector2(-1, -1)

	return mountains[mountain_id]["mine_point"]


func get_resource_amount(resource_id):
	if resource_manager == null:
		return 0

	return resource_manager.get_amount(resource_id)


func get_built_mine_at_position(mouse_pos):
	if world == null:
		return ""

	for mountain_id in mountains.keys():
		var mountain = mountains[mountain_id]

		if not mountain["mine_built"]:
			continue

		var is_iron = str(mountain["resource_id"]) == "iron_ore"
		var mine_texture = stone_mine_texture

		if is_iron:
			mine_texture = iron_mine_texture

		if mine_texture == null:
			continue

		var marker_pos = world.grid_to_screen(
			mountain["mine_point"],
			map_center
		)

		var texture_size = mine_texture.get_size()
		var target_size = Vector2(80, 72)

		var scale_factor = min(
			target_size.x / texture_size.x,
			target_size.y / texture_size.y
		)

		var draw_size = texture_size * scale_factor

		var draw_pos = marker_pos - Vector2(
			draw_size.x / 2.0,
			draw_size.y
		)

		var mine_rect = Rect2(draw_pos, draw_size)

		if mine_rect.has_point(mouse_pos):
			return str(mountain_id)

	return ""
