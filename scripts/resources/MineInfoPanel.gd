extends Panel

# ZekaCity - MineInfoPanel.gd
# Godot 3.6

var mountain_system = null
var mountain_id = ""
var world = null

var info_label = null
var refill_button = null
var close_button = null


func _ready():
	rect_min_size = Vector2(280, 190)
	rect_size = Vector2(300, 210)
	visible = false

	info_label = Label.new()
	info_label.rect_position = Vector2(12, 12)
	info_label.rect_size = Vector2(276, 135)
	info_label.autowrap = true
	add_child(info_label)

	refill_button = Button.new()
	refill_button.text = "Refill Iron - $1000"
	refill_button.rect_position = Vector2(12, 155)
	refill_button.rect_size = Vector2(170, 32)
	refill_button.connect("pressed", self, "_on_refill_pressed")
	add_child(refill_button)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.rect_position = Vector2(192, 155)
	close_button.rect_size = Vector2(85, 32)
	close_button.connect("pressed", self, "hide_panel")
	add_child(close_button)


func show_for_mine(system, selected_mountain_id, world_node):
	mountain_system = system
	mountain_id = str(selected_mountain_id)
	world = world_node

	if not is_inside_tree():
		return

	_refresh_info()
	visible = true


func hide_panel():
	visible = false


func _refresh_info():
	if mountain_system == null or mountain_system.mine_system == null:
		info_label.text = "Mine information unavailable."
		refill_button.visible = false
		return

	if not mountain_system.mine_system.has_mine(mountain_id):
		info_label.text = "No mine found."
		refill_button.visible = false
		return

	var resource_id = mountain_system.mine_system.get_mine_resource(mountain_id)
	var active = mountain_system.mine_system.is_mine_active(mountain_id)
	var remaining = mountain_system.mine_system.get_remaining(mountain_id)
	var extracted = mountain_system.mine_system.get_extracted(mountain_id)

	var resource_name = "Stone"

	if resource_id == "iron_ore":
		resource_name = "Iron"

	var status_text = "Active"

	if not active:
		status_text = "Stopped"

	var remaining_text = "Unlimited"

	if remaining >= 0:
		remaining_text = str(remaining) + " units"

	info_label.text = (
		"Mine: " + resource_name + "\n"
		+ "Status: " + status_text + "\n"
		+ "Remaining: " + remaining_text + "\n"
		+ "Total extracted: " + str(extracted) + "\n"
		+ "Production: 1 unit / 5 seconds"
	)

	refill_button.visible = resource_id == "iron_ore"

func _on_refill_pressed():
	if mountain_system == null:
		return

	var success = mountain_system.mine_system.refill_iron(
		mountain_id,
		mountain_system.city_treasury
	)

	if success:
		if world != null and world.has_method("_update_treasury_label"):
			world._update_treasury_label()

	_refresh_info()
