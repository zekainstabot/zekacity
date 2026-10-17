
extends Panel

# ZekaCity - WarehouseInfoPanel.gd
# Godot 3.6
# نمایش ظرفیت تجمیعی انبارهای شهر و موجودی منابع

var world = null
var title_label = null
var capacity_label = null
var used_label = null
var free_label = null
var percent_label = null
var progress_bar = null
var resources_label = null
var close_button = null


func _ready():
	rect_size = Vector2(340, 310)
	rect_position = Vector2(20, 20)
	raise()

	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.12, 0.16, 0.20, 0.97)
	background.border_color = Color(0.42, 0.58, 0.65, 1)
	background.set_border_width_all(2)
	background.set_corner_radius_all(8)
	add_stylebox_override("panel", background)

	var layout = VBoxContainer.new()
	layout.anchor_right = 1
	layout.anchor_bottom = 1
	layout.margin_left = 14
	layout.margin_top = 12
	layout.margin_right = -14
	layout.margin_bottom = -12
	layout.add_constant_override("separation", 8)
	add_child(layout)

	title_label = Label.new()
	title_label.text = "وضعیت انبارهای شهر"
	title_label.align = Label.ALIGN_CENTER
	title_label.add_color_override("font_color", Color(0.8, 0.95, 1))
	layout.add_child(title_label)

	var separator = HSeparator.new()
	layout.add_child(separator)

	capacity_label = _create_label(layout)
	used_label = _create_label(layout)
	free_label = _create_label(layout)
	percent_label = _create_label(layout)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.percent_visible = false
	progress_bar.rect_min_size = Vector2(0, 20)
	layout.add_child(progress_bar)

	var resources_title = Label.new()
	resources_title.text = "موجودی منابع:"
	resources_title.add_color_override("font_color", Color(1, 0.85, 0.55))
	layout.add_child(resources_title)

	resources_label = Label.new()
	resources_label.autowrap = true
	resources_label.rect_min_size = Vector2(0, 55)
	layout.add_child(resources_label)

	close_button = Button.new()
	close_button.text = "بستن"
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.connect("pressed", self, "hide_panel")
	layout.add_child(close_button)

	refresh_info()


func _create_label(parent):
	var label = Label.new()
	label.add_color_override("font_color", Color(0.94, 0.96, 0.98))
	parent.add_child(label)
	return label


func show_info(target_world):
	world = target_world
	refresh_info()
	show()


func refresh_info():
	if world == null:
		return

	var storage = world.get("storage_system")
	var resources = world.get("resource_manager")

	if storage == null or resources == null:
		capacity_label.text = "ظرفیت کل: اطلاعات در دسترس نیست"
		used_label.text = "فضای اشغال‌شده: —"
		free_label.text = "فضای خالی: —"
		percent_label.text = "درصد پرشدگی: —"
		progress_bar.value = 0
		resources_label.text = "سیستم انبار یا منابع متصل نیست."
		return

	var total_capacity = int(storage.get_total_capacity())
	var used_capacity = int(storage.get_used_capacity(resources))
	var free_capacity = max(0, total_capacity - used_capacity)
	var percentage = 0.0

	if total_capacity > 0:
		percentage = float(used_capacity) * 100.0 / float(total_capacity)

	capacity_label.text = "ظرفیت کل: %d واحد" % total_capacity
	used_label.text = "فضای اشغال‌شده: %d واحد" % used_capacity
	free_label.text = "فضای خالی: %d واحد" % free_capacity
	percent_label.text = "درصد پرشدگی: %d%%" % int(round(percentage))
	progress_bar.value = clamp(percentage, 0.0, 100.0)

	var amounts = resources.get_all_amounts()
	var resource_lines = []

	for resource_id in amounts.keys():
		var resource_name = str(resource_id)

		match str(resource_id):
			"stone":
				resource_name = "سنگ"
			"iron_ore":
				resource_name = "سنگ‌آهن"

		resource_lines.append(
			"%s: %d واحد" % [
				resource_name,
				int(amounts[resource_id])
			]
		)

	if resource_lines.empty():
		resources_label.text = "انبار خالی است."
	else:
		resources_label.text = PoolStringArray(resource_lines).join("\n")


func hide_panel():
	hide()
