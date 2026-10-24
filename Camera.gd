
extends Camera2D

var dragging = false
var last_drag_position = Vector2.ZERO

var zoom_min = 0.5
var zoom_max = 1.5
var zoom_step = 0.08

var touch_points = {}
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
	# Ignore camera mouse controls when interacting with
	# the construction panel. Do not mark the event handled,
	# so the UI can still receive its scroll input.
	if event is InputEventMouseButton:
		if _is_over_construction_panel(event.position):
			if event.button_index == BUTTON_LEFT:
				dragging = false
			return

	# Mouse controls for PC
	if event is InputEventMouseButton:
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

	# Touch controls for Android
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position

			if touch_points.size() == 2:
				last_pinch_distance = _get_pinch_distance()
				dragging = false
		else:
			touch_points.erase(event.index)
			last_pinch_distance = 0.0

			if touch_points.size() == 1:
				dragging = false

	elif event is InputEventScreenDrag:
		if not touch_points.has(event.index):
			return

		var old_distance = last_pinch_distance
		touch_points[event.index] = event.position

		if touch_points.size() >= 2:
			var new_distance = _get_pinch_distance()

			if old_distance > 0.0 and new_distance > 0.0:
				var factor = old_distance / new_distance
				var new_zoom = zoom * factor

				new_zoom.x = clamp(
					new_zoom.x, zoom_min, zoom_max
				)
				new_zoom.y = clamp(
					new_zoom.y, zoom_min, zoom_max
				)

				zoom = new_zoom

			last_pinch_distance = new_distance

		elif touch_points.size() == 1:
			global_position -= event.relative * zoom


func _apply_zoom(amount, screen_position):
	var old_zoom = zoom.x
	var new_zoom = clamp(
		old_zoom + amount, zoom_min, zoom_max
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
