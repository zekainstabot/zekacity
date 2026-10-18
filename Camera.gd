
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


func _input(event):
	# Mouse controls for PC testing
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			dragging = event.pressed
			if dragging:
				last_drag_position = event.position

		elif event.button_index == BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(-zoom_step, event.position)

		elif event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(zoom_step, event.position)

	elif event is InputEventMouseMotion and dragging:
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

	elif event is InputEventScreenDrag:
		if not touch_points.has(event.index):
			return

		var previous_points = touch_points.duplicate()
		touch_points[event.index] = event.position

		if touch_points.size() >= 2:
			var new_distance = _get_pinch_distance_from_points(touch_points)

			if last_pinch_distance > 0.0 and new_distance > 0.0:
				var difference = new_distance - last_pinch_distance
				var factor = last_pinch_distance / new_distance

				var new_zoom = zoom * factor
				new_zoom.x = clamp(new_zoom.x, zoom_min, zoom_max)
				new_zoom.y = clamp(new_zoom.y, zoom_min, zoom_max)

				zoom = new_zoom

			last_pinch_distance = new_distance

		elif touch_points.size() == 1:
			global_position -= event.relative * zoom


func _apply_zoom(amount, screen_position):
	var old_zoom = zoom.x
	var new_zoom = clamp(old_zoom + amount, zoom_min, zoom_max)

	if is_equal_approx(old_zoom, new_zoom):
		return

	var screen_center = get_viewport_rect().size / 2.0
	var world_position_before = get_camera_screen_position(screen_position, screen_center)

	zoom = Vector2(new_zoom, new_zoom)

	var world_position_after = get_camera_screen_position(screen_position, screen_center)
	global_position += world_position_before - world_position_after


func get_camera_screen_position(screen_position, screen_center):
	return global_position + (screen_position - screen_center) * zoom


func _get_pinch_distance():
	if touch_points.size() < 2:
		return 0.0

	var keys = touch_points.keys()
	return touch_points[keys[0]].distance_to(touch_points[keys[1]])


func _get_pinch_distance_from_points(points):
	if points.size() < 2:
		return 0.0

	var keys = points.keys()
	return points[keys[0]].distance_to(points[keys[1]])
