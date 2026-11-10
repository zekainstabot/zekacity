extends Node2D

# One tree per CanvasItem allows correct interleaving with building sprites.
var tree_id = 0


func _draw():
	var sway = float(tree_id % 3) * 2.0
	# Trunk
	draw_rect(Rect2(Vector2(-3, -15), Vector2(6, 18)), Color(0.34, 0.20, 0.10))
	# Layered pine canopy
	draw_colored_polygon(PoolVector2Array([
		Vector2(-18 + sway, -12), Vector2(0, -48),
		Vector2(18 + sway, -12)
	]), Color(0.10, 0.36, 0.19))
	draw_colored_polygon(PoolVector2Array([
		Vector2(-14, -25), Vector2(0, -58),
		Vector2(14, -25)
	]), Color(0.16, 0.48, 0.24))
	draw_circle(Vector2(-5, -38), 3.0, Color(0.34, 0.62, 0.31))
