extends Camera2D

var dragging = false

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			dragging = event.pressed

	elif event is InputEventMouseMotion and dragging:
		global_position -= event.relative / zoom
