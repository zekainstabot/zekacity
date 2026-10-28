extends Camera2D

var dragging = false
var last_drag_position = Vector2.ZERO

var zoom_min = 0.5
var zoom_max = 1.5
var zoom_step = 0.08

var touch_points = {}
var ui_touch_points = {}
var last_pinch_distance = 0.0


func _ready():
	current = true
	zoom = Vector2.ONE


func _is_over_construction_panel(screen_position):
	var root = get_tree().get_root()
	var construction_ui = root.find_node(
		"ConstructionUI", true, false
	)

	if construction_ui == null:
		return false

	if not construction_ui.is_visible_in_tree():
		return false

	var panel = construction_ui.get_node_or_null(
		"ConstructionPanel"
	)

	if panel == null:
		return false

	if not panel.is_visible_in_tree():
		return false

	return panel.get_global_rect().has_point(screen_position)


func _input(event):
	# Mouse controls
	if event is InputEventMouseButton:
		if _is_over_construction_panel(event.position):
			if event.button_index == BUTTON_LEFT:
				dragging = false
			return

		if event.button_index == BUTTON_LEFT:
			dragging = event.pressed

			if dragging:
				last_drag_position = event.position

		elif event.button_index == BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(-zoom_step, event.position)

		elif event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(zoom_step, event.position)

	elif event is InputEventMouseMotion:
		if dragging:
			if _is_over_construction_panel(event.position):
				dragging = false
				return

			global_position -= event.relative * zoom

	# Android touch controls
	elif event is InputEventScreenTouch:
		if event.pressed:
			if _is_over_construction_panel(event.position):
				ui_touch_points[event.index] = true
				dragging = false
				return

			touch_points[event.index] = event.position

			if ui_touch_points.size() > 0:
				dragging = false
				return

			if touch_points.size() >= 2:
				last_pinch_distance = _get_pinch_distance()
				dragging = false

		else:
			touch_points.erase(event.index)
			ui_touch_points.erase(event.index)
			last_pinch_distance = 0.0
			dragging = false

	elif event is InputEventScreenDrag:
		if ui_touch_points.has(event.index):
			return

		if ui_touch_points.size() > 0:
			return

		if not touch_points.has(event.index):
			return

		if _is_over_construction_panel(event.position):
			ui_touch_points[event.index] = true
			touch_points.erase(event.index)
			dragging = false
			last_pinch_distance = 0.0
			return

		var old_distance = last_pinch_distance

		touch_points[event.index] = event.position

		if touch_points.size() >= 2:
			var new_distance = _get_pinch_distance()

			if old_distance > 0.0 and new_distance > 0.0:
				_apply_pinch_zoom(
					old_distance,
					new_distance
				)

			last_pinch_distance = new_distance

		elif touch_points.size() == 1:
			global_position -= event.relative * zoom


func _apply_pinch_zoom(old_distance, new_distance):
	if old_distance <= 0.0 or new_distance <= 0.0:
		return

	var keys = touch_points.keys()

	if keys.size() < 2:
		return

	var point_a = touch_points[keys[0]]
	var point_b = touch_points[keys[1]]
	var midpoint = (point_a + point_b) / 2.0

	var screen_center = get_viewport_rect().size / 2.0

	# Keep the map point beneath the fingers fixed during zoom.
	var world_anchor = global_position + (
		(midpoint - screen_center) * zoom
	)

	var factor = old_distance / new_distance
	var new_zoom_value = clamp(
		zoom.x * factor,
		zoom_min,
		zoom_max
	)

	var new_zoom = Vector2(
		new_zoom_value,
		new_zoom_value
	)

	if is_equal_approx(new_zoom.x, zoom.x):
		return

	zoom = new_zoom

	global_position = world_anchor - (
		(midpoint - screen_center) * zoom
	)


func _apply_zoom(amount, screen_position):
	var old_zoom = zoom.x
	var new_zoom = clamp(
		old_zoom + amount,
		zoom_min,
		zoom_max
	)

	if is_equal_approx(old_zoom, new_zoom):
		return

	var screen_center = get_viewport_rect().size / 2.0

	var world_position_before = get_camera_screen_position(
		screen_position,
		screen_center
	)

	zoom = Vector2(new_zoom, new_zoom)

	var world_position_after = get_camera_screen_position(
		screen_position,
		screen_center
	)

	global_position += (
		world_position_before - world_position_after
	)


func get_camera_screen_position(screen_position, screen_center):
	return global_position + (
		(screen_position - screen_center) * zoom
	)


func _get_pinch_distance():
	if touch_points.size() < 2:
		return 0.0

	var keys = touch_points.keys()

	return touch_points[keys[0]].distance_to(
		touch_points[keys[1]]
	)
